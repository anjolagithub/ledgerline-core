// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Identifies a party and the token involved in one leg of a loan (funding or repayment).
struct LoanFlow {
    address from;
    address to;
    address withToken;
}

enum LoanStatus {
    Created,
    Funded,
    PartlyRepaid,
    Repaid,
    Expired
}

struct LoanTerms {
    uint256 loanAmount;
    uint256 expectedRepaymentAmount;
    uint256 deadlineTimestamp;
}

/// @notice Full record of a loan mirrored from the source chain onto Creditcoin.
struct LoanOrder {
    bytes32 sourceChainKey;
    uint256 sourceLoanId;
    LoanFlow repayFlow;          // repayFlow.from == borrower, repayFlow.to == lender
    LoanTerms terms;
    LoanStatus status;
    uint256 repaidAmount;
    uint256 createdAtBlock;
}

/// @notice Original to LedgerLine — no equivalent exists in Creditcoin's reference examples.
///         This is the actual credit-scoring engine: derived entirely from verified,
///         on-chain-proven repayment history, never self-reported.
struct CreditMetrics {
    uint16 score;                    // 0–1000
    uint256 totalVerifiedRepayments; // cumulative stablecoin value, across all loans
    uint256 completedLoanCount;
    uint256 lastUpdated;
}

library LoanIdLib {
    function loanKey(bytes32 sourceChainKey, uint256 sourceLoanId) internal pure returns (bytes32) {
        return keccak256(abi.encode(sourceChainKey, sourceLoanId));
    }
}