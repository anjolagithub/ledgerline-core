// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LedgerLineSourceSettlement} from "../src/LedgerLineSourceSettlement.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract LedgerLineSourceSettlementTest is Test {
    LedgerLineSourceSettlement settlement;
    MockERC20 token;
    address lender = address(this);
    address borrower = address(0xB0B);

    function setUp() public {
        settlement = new LedgerLineSourceSettlement();
        token = new MockERC20();
        token.transfer(borrower, 10_000 ether);
    }

    function test_FundLoan_TransfersToBorrower() public {
        token.approve(address(settlement), 1000 ether);
        settlement.fundLoan(1, borrower, address(token), 1000 ether);
        assertEq(token.balanceOf(borrower), 11_000 ether);
    }

    function test_RepayLoan_TransfersToLender() public {
        vm.startPrank(borrower);
        token.approve(address(settlement), 500 ether);
        settlement.repayLoan(1, lender, address(token), 500 ether);
        vm.stopPrank();
        assertEq(token.balanceOf(borrower), 9_500 ether);
    }

    function test_RevertWhen_FundingZeroAmount() public {
        vm.expectRevert(LedgerLineSourceSettlement.ZeroAmount.selector);
        settlement.fundLoan(1, borrower, address(token), 0);
    }

    function test_RevertWhen_RepayingWithoutApproval() public {
        vm.prank(borrower);
        vm.expectRevert();
        settlement.repayLoan(1, lender, address(token), 500 ether);
    }
}