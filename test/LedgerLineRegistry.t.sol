// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LedgerLineRegistry} from "../src/LedgerLineRegistry.sol";
import {LoanFlow, LoanTerms, LoanOrder, LoanStatus, CreditMetrics} from "../src/LedgerLineTypes.sol";

contract LedgerLineRegistryTest is Test {
    LedgerLineRegistry registry;
    address admin = address(this);
    address borrower = address(0xB0B);
    address lender = address(0x1E4D);
    address token = address(0x7070707070707070707070707070707070707A);
    bytes32 sourceChainKey = bytes32(uint256(1)); // Ethereum Sepolia

    function setUp() public {
        registry = new LedgerLineRegistry(admin);
    }

    function test_RegisterLoan_SetsCreatedStatus() public {
        _registerSampleLoan(1);
        LoanOrder memory loan = registry.getLoanOrder(sourceChainKey, 1);
        assertEq(uint8(loan.status), uint8(LoanStatus.Created));
    }

    function test_RevertWhen_RegisteringDuplicateLoan() public {
        _registerSampleLoan(1);
        vm.expectRevert();
        _registerSampleLoan(1);
    }

    function test_FullRepayment_IncrementsScore() public {
        _registerSampleLoan(1);
        registry.markLoanFunded(sourceChainKey, 1);
        registry.recordLoanRepayment(sourceChainKey, 1, 1000 ether);

        CreditMetrics memory profile = registry.getCreditProfile(borrower);
        assertEq(profile.score, 515); // BASE_SCORE(500) + SCORE_INCREMENT(15)
        assertEq(profile.completedLoanCount, 1);
    }

    function test_PartialRepayment_DoesNotIncrementScore() public {
        _registerSampleLoan(1);
        registry.markLoanFunded(sourceChainKey, 1);
        registry.recordLoanRepayment(sourceChainKey, 1, 400 ether); // < 1000 ether owed

        CreditMetrics memory profile = registry.getCreditProfile(borrower);
        assertEq(profile.score, 500); // stays at BASE_SCORE — no increment on partial
    }

    function testFuzz_ScoreNeverExceedsMax(uint8 repaymentCount) public {
        vm.assume(repaymentCount > 0 && repaymentCount < 100);
        for (uint256 i = 0; i < repaymentCount; i++) {
            _registerSampleLoan(i + 1);
            registry.markLoanFunded(sourceChainKey, i + 1);
            registry.recordLoanRepayment(sourceChainKey, i + 1, 1000 ether);
        }
        CreditMetrics memory profile = registry.getCreditProfile(borrower);
        assertLe(profile.score, registry.MAX_SCORE());
    }

    function _registerSampleLoan(uint256 loanId) internal {
        registry.registerLoan(
            sourceChainKey,
            loanId,
            LoanFlow({from: borrower, to: lender, withToken: token}),
            LoanTerms({loanAmount: 1000 ether, expectedRepaymentAmount: 1000 ether, deadlineTimestamp: block.timestamp + 30 days})
        );
    }
}