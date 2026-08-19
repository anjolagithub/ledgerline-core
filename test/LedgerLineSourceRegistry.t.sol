// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LedgerLineSourceRegistry} from "../src/LedgerLineSourceRegistry.sol";

contract LedgerLineSourceRegistryTest is Test {
    LedgerLineSourceRegistry registry;
    address owner = address(this);
    address lender = address(this);
    address borrower = address(0xB0B);
    address token = address(0x7070707070707070707070707070707070707A);

    function setUp() public {
        registry = new LedgerLineSourceRegistry(owner);
        registry.approveLender(lender);
    }

    function test_RegisterLoan_ReturnsIncrementingIds() public {
        uint256 id1 = registry.registerLoan(borrower, token, 1000 ether, 1100 ether, block.timestamp + 30 days);
        uint256 id2 = registry.registerLoan(borrower, token, 500 ether, 550 ether, block.timestamp + 30 days);
        assertEq(id1, 1);
        assertEq(id2, 2);
    }

    function test_RegisterLoan_EmitsCorrectEvent() public {
        vm.expectEmit(true, true, true, true);
        emit LedgerLineSourceRegistry.LoanRegistered(1, lender, borrower, 1000 ether, 1100 ether, block.timestamp + 30 days);
        registry.registerLoan(borrower, token, 1000 ether, 1100 ether, block.timestamp + 30 days);
    }

    function test_RevertWhen_BorrowerIsZeroAddress() public {
        vm.expectRevert(LedgerLineSourceRegistry.ZeroAddress.selector);
        registry.registerLoan(address(0), token, 1000 ether, 1100 ether, block.timestamp + 30 days);
    }

    function test_RevertWhen_LoanAmountIsZero() public {
        vm.expectRevert(LedgerLineSourceRegistry.ZeroAmount.selector);
        registry.registerLoan(borrower, token, 0, 1100 ether, block.timestamp + 30 days);
    }

    function test_RevertWhen_DeadlineIsInPast() public {
        vm.warp(1000);
        vm.expectRevert(LedgerLineSourceRegistry.DeadlineInPast.selector);
        registry.registerLoan(borrower, token, 1000 ether, 1100 ether, 500);
    }

    // ── New: lender allowlist coverage — this is the actual fix being tested ──

 function test_RevertWhen_UnapprovedLenderRegisters() public {
    address badActor = makeAddr("badActor");
    vm.prank(badActor);
    vm.expectRevert(abi.encodeWithSelector(LedgerLineSourceRegistry.LenderNotApproved.selector, badActor));
    registry.registerLoan(borrower, token, 1000 ether, 1100 ether, block.timestamp + 30 days);
}

    function test_ApproveLender_AllowsRegistration() public {
        address newLender = address(0xCAFE);
        vm.prank(newLender);
        vm.expectRevert(abi.encodeWithSelector(LedgerLineSourceRegistry.LenderNotApproved.selector, newLender));
        registry.registerLoan(borrower, token, 1000 ether, 1100 ether, block.timestamp + 30 days);

        registry.approveLender(newLender);

        vm.prank(newLender);
        uint256 loanId = registry.registerLoan(borrower, token, 1000 ether, 1100 ether, block.timestamp + 30 days);
        assertEq(loanId, 1);
    }

    function test_RevokeLender_BlocksFutureRegistration() public {
        registry.revokeLender(lender);
        vm.expectRevert(abi.encodeWithSelector(LedgerLineSourceRegistry.LenderNotApproved.selector, lender));
        registry.registerLoan(borrower, token, 1000 ether, 1100 ether, block.timestamp + 30 days);
    }
function test_RevertWhen_NonOwnerApprovesLender() public {
    address notOwner = makeAddr("notOwner");
    vm.prank(notOwner);
    vm.expectRevert();
    registry.approveLender(address(0xCAFE));
}

}