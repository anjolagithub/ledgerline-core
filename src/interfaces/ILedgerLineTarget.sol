// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LoanFlow, LoanTerms} from "../LedgerLineTypes.sol";

/// @title ILedgerLineTarget
/// @notice Interface the readability manager calls into after a proof verifies.
///         Separating this from the manager keeps proof-verification concerns
///         (which chain, which precompile) decoupled from credit-scoring concerns
///         (which borrower, what score) — two different reasons to change.
interface ILedgerLineTarget {
    function registerLoan(
        bytes32 sourceChainKey,
        uint256 sourceLoanId,
        LoanFlow calldata repayFlow,
        LoanTerms calldata terms
    ) external;

    function markLoanFunded(bytes32 sourceChainKey, uint256 sourceLoanId) external;

    function recordLoanRepayment(bytes32 sourceChainKey, uint256 sourceLoanId, uint256 amount) external;
}