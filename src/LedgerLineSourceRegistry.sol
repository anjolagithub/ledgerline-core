// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LoanFlow, LoanTerms} from "./LedgerLineTypes.sol";

/// @title LedgerLineSourceRegistry
/// @notice Minimal source-chain contract. Its only job is to emit clean events the
///         hub chain can prove against. Business logic lives on Creditcoin — except
///         for one deliberate exception: lender approval. This check MUST live here,
///         on the source chain, because it's the only place that can gate who is
///         allowed to originate a loan in the first place. The hub-side manager only
///         checks *which contract* emitted an event, not *who called it* — so without
///         this allowlist, anyone could call registerLoan() and self-deal a fake loan
///         through the otherwise-legitimate pipeline.
contract LedgerLineSourceRegistry is Ownable {
    error DeadlineInPast();
    error ZeroAddress();
    error ZeroAmount();
    error LenderNotApproved(address lender);

    uint256 private _nextLoanId = 1;

    mapping(address => bool) public approvedLenders;

    event LoanRegistered(
        uint256 indexed loanId,
        address indexed lender,
        address indexed borrower,
        uint256 loanAmount,
        uint256 expectedRepaymentAmount,
        uint256 deadlineTimestamp
    );
    event LenderApproved(address indexed lender);
    event LenderRevoked(address indexed lender);

    modifier onlyApprovedLender() {
        if (!approvedLenders[msg.sender]) revert LenderNotApproved(msg.sender);
        _;
    }

    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Admin-gated allowlisting — represents the accredited/KYC'd lender
    ///         onboarding step. Mocked as owner-only for the hackathon; a production
    ///         version would tie this to real KYB/accreditation checks off-chain.
    function approveLender(address lender) external onlyOwner {
        if (lender == address(0)) revert ZeroAddress();
        approvedLenders[lender] = true;
        emit LenderApproved(lender);
    }

    function revokeLender(address lender) external onlyOwner {
        approvedLenders[lender] = false;
        emit LenderRevoked(lender);
    }

    function registerLoan(
        address borrower,
        address withToken,
        uint256 loanAmount,
        uint256 expectedRepaymentAmount,
        uint256 deadlineTimestamp
    ) external onlyApprovedLender returns (uint256 loanId) {
        if (borrower == address(0) || withToken == address(0)) revert ZeroAddress();
        if (loanAmount == 0 || expectedRepaymentAmount == 0) revert ZeroAmount();
        if (deadlineTimestamp <= block.timestamp) revert DeadlineInPast();

        loanId = _nextLoanId++;

        emit LoanRegistered(
            loanId,
            msg.sender, // lender — now guaranteed approved
            borrower,
            loanAmount,
            expectedRepaymentAmount,
            deadlineTimestamp
        );
    }
}