// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ILedgerLineRegistryRead {
    struct CreditMetrics {
        uint16 score;
        uint256 totalVerifiedRepayments;
        uint256 completedLoanCount;
        uint256 lastUpdated;
    }
    function getCreditProfile(address borrower) external view returns (CreditMetrics memory);
}

/// @title LedgerLineFinancing
/// @notice Reads verified credit intelligence from the existing LedgerLineRegistry
///         and applies a deterministic, documented underwriting policy to invoice
///         financing requests. This contract does not modify, own, or duplicate
///         any state from LedgerLineRegistry — it is a pure downstream consumer.
contract LedgerLineFinancing {
    ILedgerLineRegistryRead public immutable creditRegistry;

    uint16 public constant MIN_ELIGIBLE_SCORE = 600;
    uint256 public constant MIN_COMPLETED_LOANS = 1;

    enum InvoiceStatus { Outstanding, FinancingRequested, Financed }

    struct Invoice {
        address seller;
        string buyerName;
        uint256 amount;
        uint256 dueTimestamp;
        InvoiceStatus status;
        uint256 approvedAdvance;
    }

    mapping(uint256 => Invoice) public invoices;
    uint256 private _nextInvoiceId = 1;

    error NotEligible(uint16 score, uint256 completedLoans);
    error InvoiceNotFound(uint256 invoiceId);
    error NotInvoiceOwner();
    error InvalidInvoiceStatus(InvoiceStatus status);

    event InvoiceRegistered(uint256 indexed invoiceId, address indexed seller, uint256 amount);
    event FinancingRequested(uint256 indexed invoiceId, uint256 approvedAdvance, uint16 scoreAtApproval);

    constructor(address _creditRegistry) {
        creditRegistry = ILedgerLineRegistryRead(_creditRegistry);
    }

    function registerInvoice(string calldata buyerName, uint256 amount, uint256 dueTimestamp)
        external
        returns (uint256 invoiceId)
    {
        invoiceId = _nextInvoiceId++;
        invoices[invoiceId] = Invoice(msg.sender, buyerName, amount, dueTimestamp, InvoiceStatus.Outstanding, 0);
        emit InvoiceRegistered(invoiceId, msg.sender, amount);
    }

    /// @notice Deterministic underwriting policy, documented in full here — no
    ///         hidden logic, no off-chain model, no discretionary override.
    ///
    ///         Tier 1 — score 600-749, >=1 completed loan: 50% advance rate
    ///         Tier 2 — score 750-899, >=1 completed loan: 65% advance rate
    ///         Tier 3 — score 900-1000, >=1 completed loan: 80% advance rate
    ///         Below score 600 or zero completed loans: not eligible.
    ///
    ///         The computed advance is additionally capped at the borrower's
    ///         totalVerifiedRepayments — financing offered can never exceed
    ///         proven, verified repayment history.
    function calculateEligibility(address borrower, uint256 invoiceAmount)
        public
        view
        returns (bool eligible, uint256 maxAdvance, uint8 advanceRatePercent)
    {
        ILedgerLineRegistryRead.CreditMetrics memory profile = creditRegistry.getCreditProfile(borrower);

        if (profile.score < MIN_ELIGIBLE_SCORE || profile.completedLoanCount < MIN_COMPLETED_LOANS) {
            return (false, 0, 0);
        }

        if (profile.score >= 900) advanceRatePercent = 80;
        else if (profile.score >= 750) advanceRatePercent = 65;
        else advanceRatePercent = 50;

        uint256 rawAdvance = (invoiceAmount * advanceRatePercent) / 100;
        maxAdvance = rawAdvance > profile.totalVerifiedRepayments ? profile.totalVerifiedRepayments : rawAdvance;
        eligible = true;
    }

    function requestFinancing(uint256 invoiceId) external {
        Invoice storage inv = invoices[invoiceId];
        if (inv.seller == address(0)) revert InvoiceNotFound(invoiceId);
        if (inv.seller != msg.sender) revert NotInvoiceOwner();
        if (inv.status != InvoiceStatus.Outstanding) revert InvalidInvoiceStatus(inv.status);

        (bool eligible, uint256 maxAdvance, ) = calculateEligibility(msg.sender, inv.amount);
        if (!eligible) {
            ILedgerLineRegistryRead.CreditMetrics memory p = creditRegistry.getCreditProfile(msg.sender);
            revert NotEligible(p.score, p.completedLoanCount);
        }

        inv.status = InvoiceStatus.FinancingRequested;
        inv.approvedAdvance = maxAdvance;

        ILedgerLineRegistryRead.CreditMetrics memory p2 = creditRegistry.getCreditProfile(msg.sender);
        emit FinancingRequested(invoiceId, maxAdvance, p2.score);
    }

    function getInvoice(uint256 invoiceId) external view returns (Invoice memory) {
        return invoices[invoiceId];
    }
}