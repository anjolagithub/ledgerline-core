// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ILedgerLineTarget} from "./interfaces/ILedgerLineTarget.sol";
import {LoanFlow, LoanTerms, LoanOrder, LoanStatus, CreditMetrics, LoanIdLib} from "./LedgerLineTypes.sol";

/// @title LedgerLineRegistry
/// @notice The actual credit-scoring engine. Everything upstream (proof verification,
///         event decoding) exists purely to feed trustworthy data into this contract.
///         This is the piece with no equivalent in Creditcoin's own reference examples.
contract LedgerLineRegistry is ILedgerLineTarget, AccessControl {
    bytes32 public constant READABILITY_ROLE = keccak256("READABILITY_ROLE");

    uint16 public constant MAX_SCORE = 1000;
    uint16 public constant BASE_SCORE = 500;
    uint16 public constant SCORE_INCREMENT = 15;

    mapping(bytes32 => LoanOrder) public loanOrders;       // keyed by LoanIdLib.loanKey
    mapping(bytes32 => bool) public registeredLoans;
    mapping(address => CreditMetrics) public creditProfiles; // keyed by borrower (source-chain address)

    event LoanRegistered(bytes32 indexed loanKey, address indexed borrower, uint256 loanAmount);
    event LoanFunded(bytes32 indexed loanKey);
    event LoanPartiallyRepaid(bytes32 indexed loanKey, uint256 amount);
    event LoanRepaid(bytes32 indexed loanKey);
    event CreditScoreUpdated(address indexed borrower, uint16 newScore, uint256 totalVerifiedRepayments);

    error LoanAlreadyRegistered(bytes32 loanKey);
    error LoanNotRegistered(bytes32 loanKey);
    error InvalidStatusForFunding(LoanStatus status);
    error InvalidStatusForRepayment(LoanStatus status);
    error LoanExpired(uint256 deadline);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(READABILITY_ROLE, admin); // manager granted separately once deployed
    }

    function registerLoan(
        bytes32 sourceChainKey,
        uint256 sourceLoanId,
        LoanFlow calldata repayFlow,
        LoanTerms calldata terms
    ) external override onlyRole(READABILITY_ROLE) {
        bytes32 key = LoanIdLib.loanKey(sourceChainKey, sourceLoanId);
        if (registeredLoans[key]) revert LoanAlreadyRegistered(key);

        registeredLoans[key] = true;
        loanOrders[key] = LoanOrder({
            sourceChainKey: sourceChainKey,
            sourceLoanId: sourceLoanId,
            repayFlow: repayFlow,
            terms: terms,
            status: LoanStatus.Created,
            repaidAmount: 0,
            createdAtBlock: block.number
        });

        emit LoanRegistered(key, repayFlow.from, terms.loanAmount);
    }

    function markLoanFunded(bytes32 sourceChainKey, uint256 sourceLoanId) external override onlyRole(READABILITY_ROLE) {
        bytes32 key = LoanIdLib.loanKey(sourceChainKey, sourceLoanId);
        LoanOrder storage loan = loanOrders[key];
        if (!registeredLoans[key]) revert LoanNotRegistered(key);
        if (loan.status != LoanStatus.Created) revert InvalidStatusForFunding(loan.status);

        loan.status = LoanStatus.Funded;
        emit LoanFunded(key);
    }

    /// @notice The scoring hook. Score only increments on FULL repayment, not per partial
    ///         payment — a deliberate design choice to prevent gaming the score via many
    ///         tiny repayments. See docs/CREDIT_SCORING_MODEL.md for the rationale.
    function recordLoanRepayment(bytes32 sourceChainKey, uint256 sourceLoanId, uint256 amount)
        external
        override
        onlyRole(READABILITY_ROLE)
    {
        bytes32 key = LoanIdLib.loanKey(sourceChainKey, sourceLoanId);
        LoanOrder storage loan = loanOrders[key];
        if (!registeredLoans[key]) revert LoanNotRegistered(key);
        if (loan.status != LoanStatus.Funded && loan.status != LoanStatus.PartlyRepaid) {
            revert InvalidStatusForRepayment(loan.status);
        }
        if (block.timestamp > loan.terms.deadlineTimestamp) revert LoanExpired(loan.terms.deadlineTimestamp);

        loan.repaidAmount += amount;

        address borrower = loan.repayFlow.from;
        CreditMetrics storage profile = creditProfiles[borrower];
        if (profile.score == 0) {
            profile.score = BASE_SCORE; // first-touch initialization
        }
        profile.totalVerifiedRepayments += amount;
        profile.lastUpdated = block.timestamp;

        if (loan.repaidAmount >= loan.terms.expectedRepaymentAmount) {
            loan.status = LoanStatus.Repaid;
            profile.completedLoanCount += 1;
            if (profile.score < MAX_SCORE) {
                uint16 next = profile.score + SCORE_INCREMENT;
                profile.score = next > MAX_SCORE ? MAX_SCORE : next;
            }
            emit LoanRepaid(key);
        } else {
            loan.status = LoanStatus.PartlyRepaid;
            emit LoanPartiallyRepaid(key, amount);
        }

        emit CreditScoreUpdated(borrower, profile.score, profile.totalVerifiedRepayments);
    }

    function getCreditProfile(address borrower) external view returns (CreditMetrics memory) {
        return creditProfiles[borrower];
    }

    function getLoanOrder(bytes32 sourceChainKey, uint256 sourceLoanId) external view returns (LoanOrder memory) {
        return loanOrders[LoanIdLib.loanKey(sourceChainKey, sourceLoanId)];
    }
}