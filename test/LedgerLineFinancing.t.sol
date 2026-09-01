// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LedgerLineFinancing, ILedgerLineRegistryRead} from "../src/LedgerLineFinancing.sol";
import {LedgerLineRegistry} from "../src/LedgerLineRegistry.sol";
import {LoanFlow, LoanTerms} from "../src/LedgerLineTypes.sol";

/// @notice Tests LedgerLineFinancing against a REAL LedgerLineRegistry instance,
///         not a mock — since the whole point of this contract is that it reads
///         genuine, already-verified credit data. We drive the registry into
///         known states using its real admin/READABILITY_ROLE functions, the
///         same way the actual cross-chain pipeline would.
contract LedgerLineFinancingTest is Test {
    LedgerLineFinancing financing;
    LedgerLineRegistry registry;

    address admin = address(this);
    address seller = address(0x5E11E4);
    address lowScoreSeller = address(0x10);
    bytes32 sourceChainKey = bytes32(uint256(1));

    function setUp() public {
        registry = new LedgerLineRegistry(admin);
        financing = new LedgerLineFinancing(address(registry));

        // Grant this test contract READABILITY_ROLE so it can drive the
        // registry into a realistic post-verification state, exactly as
        // LedgerLineReadabilityManager would after a real proof verifies.
        registry.grantRole(registry.READABILITY_ROLE(), admin);
    }

    /// @dev Helper: pushes `seller` through a full, real loan lifecycle on the
    ///      registry so it reaches a genuine, non-zero score and completed-loan
    ///      count — the same state the real cross-chain pipeline would produce.
    function _giveSellerVerifiedHistory(address who, uint256 loanId, uint256 amount) internal {
        registry.registerLoan(
            sourceChainKey,
            loanId,
            LoanFlow({from: who, to: address(0x1E4D), withToken: address(0x70)}),
            LoanTerms({loanAmount: amount, expectedRepaymentAmount: amount, deadlineTimestamp: block.timestamp + 30 days})
        );
        registry.markLoanFunded(sourceChainKey, loanId);
        registry.recordLoanRepayment(sourceChainKey, loanId, amount);
    }

    // ── Eligibility calculation ──

    function test_CalculateEligibility_IneligibleWithNoHistory() public view {
        (bool eligible, uint256 maxAdvance, uint8 rate) = financing.calculateEligibility(lowScoreSeller, 10_000 ether);
        assertFalse(eligible);
        assertEq(maxAdvance, 0);
        assertEq(rate, 0);
    }

    function test_CalculateEligibility_Tier1AfterOneRepayment() public {
        _giveSellerVerifiedHistory(seller, 1, 1000 ether);
        // one full repayment -> score = 500 (base) + 15 = 515, below MIN_ELIGIBLE_SCORE (600)
        (bool eligible, , ) = financing.calculateEligibility(seller, 10_000 ether);
        assertFalse(eligible); // 515 < 600, correctly NOT eligible yet
    }

    function test_CalculateEligibility_EligibleAfterEnoughRepayments() public {
        // Drive score above 600: need (600-500)/15 = ~7 completed loans
        for (uint256 i = 1; i <= 8; i++) {
            _giveSellerVerifiedHistory(seller, i, 1000 ether);
        }
        (bool eligible, uint256 maxAdvance, uint8 rate) = financing.calculateEligibility(seller, 10_000 ether);
        assertTrue(eligible);
        assertEq(rate, 50); // score in 600-749 band at this point
        assertTrue(maxAdvance > 0);
    }

    function test_CalculateEligibility_AdvanceCappedByVerifiedRepayments() public {
        // Small verified history, but a huge invoice — advance must be capped
        // at totalVerifiedRepayments, never exceed proven history.
        for (uint256 i = 1; i <= 8; i++) {
            _giveSellerVerifiedHistory(seller, i, 100 ether); // total verified = 800 ether
        }
        (bool eligible, uint256 maxAdvance, ) = financing.calculateEligibility(seller, 1_000_000 ether);
        assertTrue(eligible);
        assertLe(maxAdvance, 800 ether); // capped, not 50% of 1,000,000
    }

    // ── Invoice + financing request flow ──

    function test_RegisterInvoice_StoresCorrectData() public {
        vm.prank(seller);
        uint256 id = financing.registerInvoice("Acme Trading Ltd", 10_000 ether, block.timestamp + 30 days);
        LedgerLineFinancing.Invoice memory inv = financing.getInvoice(id);
        assertEq(inv.seller, seller);
        assertEq(inv.amount, 10_000 ether);
        assertEq(uint8(inv.status), uint8(LedgerLineFinancing.InvoiceStatus.Outstanding));
    }

    function test_RequestFinancing_SucceedsWhenEligible() public {
        for (uint256 i = 1; i <= 8; i++) {
            _giveSellerVerifiedHistory(seller, i, 1000 ether);
        }
        vm.prank(seller);
        uint256 id = financing.registerInvoice("Acme Trading Ltd", 10_000 ether, block.timestamp + 30 days);

        vm.prank(seller);
        financing.requestFinancing(id);

        LedgerLineFinancing.Invoice memory inv = financing.getInvoice(id);
        assertEq(uint8(inv.status), uint8(LedgerLineFinancing.InvoiceStatus.FinancingRequested));
        assertTrue(inv.approvedAdvance > 0);
    }

    function test_RevertWhen_RequestingFinancingWithoutEligibility() public {
        vm.prank(lowScoreSeller);
        uint256 id = financing.registerInvoice("Acme Trading Ltd", 10_000 ether, block.timestamp + 30 days);

        vm.prank(lowScoreSeller);
        vm.expectRevert(); // NotEligible — no verified history at all
        financing.requestFinancing(id);
    }

    function test_RevertWhen_NonOwnerRequestsFinancing() public {
        for (uint256 i = 1; i <= 8; i++) {
            _giveSellerVerifiedHistory(seller, i, 1000 ether);
        }
        vm.prank(seller);
        uint256 id = financing.registerInvoice("Acme Trading Ltd", 10_000 ether, block.timestamp + 30 days);

        address impersonator = address(0xBAD1);
        vm.prank(impersonator);
        vm.expectRevert(LedgerLineFinancing.NotInvoiceOwner.selector);
        financing.requestFinancing(id);
    }

    function test_RevertWhen_RequestingFinancingTwice() public {
        for (uint256 i = 1; i <= 8; i++) {
            _giveSellerVerifiedHistory(seller, i, 1000 ether);
        }
        vm.prank(seller);
        uint256 id = financing.registerInvoice("Acme Trading Ltd", 10_000 ether, block.timestamp + 30 days);

        vm.prank(seller);
        financing.requestFinancing(id);

        vm.prank(seller);
        vm.expectRevert(); // InvalidInvoiceStatus — already FinancingRequested
        financing.requestFinancing(id);
    }

    function test_RevertWhen_InvoiceDoesNotExist() public {
        vm.prank(seller);
        vm.expectRevert(); // InvoiceNotFound
        financing.requestFinancing(999);
    }
}
