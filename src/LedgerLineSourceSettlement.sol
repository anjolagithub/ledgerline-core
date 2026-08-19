// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title LedgerLineSourceSettlement
/// @notice Handles actual fund movement on the source chain: funding a loan, and
///         borrowers repaying it. Kept separate from the registry (which only records
///         terms) so each contract has one clear responsibility.
contract LedgerLineSourceSettlement {
    using SafeERC20 for IERC20;

    error ZeroAmount();
    error TransferFailed();

    event LoanFunded(uint256 indexed loanId, address indexed lender, address indexed borrower, uint256 amount);
    event LoanRepaid(uint256 indexed loanId, uint256 amount);

    function fundLoan(uint256 loanId, address borrower, address token, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        IERC20(token).safeTransferFrom(msg.sender, borrower, amount);
        emit LoanFunded(loanId, msg.sender, borrower, amount);
    }

    function repayLoan(uint256 loanId, address lender, address token, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        IERC20(token).safeTransferFrom(msg.sender, lender, amount);
        emit LoanRepaid(loanId, amount);
    }
}