// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IAttestcoinProofVerifier} from "./interfaces/IAttestcoinProofVerifier.sol";
import {ILedgerLineTarget} from "./interfaces/ILedgerLineTarget.sol";
import {LoanFlow, LoanTerms} from "./LedgerLineTypes.sol";
import {ILedgerLineProofVerifier} from "./interfaces/ILedgerLineProofVerifier.sol";
import {LedgerLineDecoder} from "./lib/LedgerLineDecoder.sol";

/// @title LedgerLineReadabilityManager
/// @notice Orchestrates: verify a source-chain event proof -> decode it -> dispatch
///         to the credit registry. Fail-closed on every check: unconfigured chain,
///         unauthorized emitter, or failed transaction status all revert rather than
///         silently no-op — directly addresses the Sybil/spoofing concern raised earlier.
contract LedgerLineReadabilityManager is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    enum Action {
        LoanRegistered,
        LoanFunded,
        LoanRepaid
    }

    // keccak256("LoanRegistered(uint256,address,address,uint256,uint256,uint256)")
bytes32 public constant LOAN_REGISTERED_EVENT =
    0x4150dd864303d6b1464100e690e63c0ea11347decbb123e909018da0470f9870;
// keccak256("LoanRepaid(uint256,uint256)")
bytes32 public constant LOAN_REPAID_EVENT =
    0x040cee90ee4799897c30ca04e5feb6fa43dbba9b6d084b4b257cdafd84ba013e;
  // keccak256("LoanFunded(uint256,address,address,uint256)")
bytes32 public constant LOAN_FUNDED_EVENT =
    0x31962dfcc960e802d8cb12e69128e6789a329952d8300113d776e53221bf4484;
    
    ILedgerLineProofVerifier public proofVerifier;
    ILedgerLineTarget public creditRegistry;

    /// @notice This hub instance mirrors exactly one source chain — fail-closed 1:1 binding.
    bytes32 public sourceChainKey;
    address public authorizedSourceRegistry;
    address public authorizedSourceSettlement;

    mapping(bytes32 => bool) public processedQueries;

    event SourceChainConfigured(bytes32 indexed chainKey, address registry, address settlement);
    event QueryProcessed(bytes32 indexed queryId, uint8 action);

    error ZeroAddress();
    error SourceChainNotConfigured();
    error InvalidSourceChainKey(bytes32 provided, bytes32 expected);
    error QueryAlreadyProcessed(bytes32 queryId);
    error UnauthorizedEmitter(address emitter, address expected);
    error InvalidAction(uint8 action);
    error ProofVerificationFailed(uint64 chainKey, uint64 blockHeight);
    error TransactionDidNotSucceed();
    error EventNotFound(bytes32 eventSignature, address expectedEmitter);

    constructor(address creditRegistry_, address proofVerifier_, address admin_) {
        if (creditRegistry_ == address(0) || proofVerifier_ == address(0) || admin_ == address(0)) {
            revert ZeroAddress();
        }
        creditRegistry = ILedgerLineTarget(creditRegistry_);
       proofVerifier = ILedgerLineProofVerifier(proofVerifier_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, admin_);
    }

    function configureSourceChain(
        bytes32 chainKey_,
        address sourceRegistry_,
        address sourceSettlement_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (sourceRegistry_ == address(0) || sourceSettlement_ == address(0)) revert ZeroAddress();
        sourceChainKey = chainKey_;
        authorizedSourceRegistry = sourceRegistry_;
        authorizedSourceSettlement = sourceSettlement_;
        emit SourceChainConfigured(chainKey_, sourceRegistry_, sourceSettlement_);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    /// @notice Entry point called by the off-chain relayer once it has a proof in hand.
    /// @dev Decoding logic is intentionally left as a stub (_decodeAndDispatch) —
    ///      full event-log parsing against real Sepolia transaction bytes depends on
    ///      the EVM receipt log layout, wired up once we test against a real testnet tx.
   function submitProof(
    uint8 action,
    uint64 blockHeight,
    bytes calldata encodedTransaction,
    IAttestcoinProofVerifier.MerkleProof calldata merkleProof,
    IAttestcoinProofVerifier.ContinuityProof calldata continuityProof
) external whenNotPaused nonReentrant {
    if (sourceChainKey == bytes32(0)) revert SourceChainNotConfigured();

    bytes32 queryId = keccak256(abi.encodePacked(sourceChainKey, blockHeight, encodedTransaction));
    if (processedQueries[queryId]) revert QueryAlreadyProcessed(queryId);

    uint64 chainKeyUint = uint64(uint256(sourceChainKey));
    bool verified = proofVerifier.verify(chainKeyUint, blockHeight, encodedTransaction, merkleProof, continuityProof);
    if (!verified) revert ProofVerificationFailed(chainKeyUint, blockHeight);

    processedQueries[queryId] = true;

    LedgerLineDecoder.ReceiptFields memory receipt = LedgerLineDecoder.decodeReceipt(encodedTransaction);
    if (receipt.status != 1) revert TransactionDidNotSucceed();

    Action act = Action(action);
    address expectedEmitter = (act == Action.LoanRegistered) ? authorizedSourceRegistry : authorizedSourceSettlement;
    bytes32 eventSig = _eventSignatureFor(act);

    (bool found, LedgerLineDecoder.LogEntry memory log) =
        LedgerLineDecoder.findLog(receipt, eventSig, expectedEmitter);
    if (!found) revert EventNotFound(eventSig, expectedEmitter);

    emit QueryProcessed(queryId, action);
    _dispatch(act, log);
}

function _eventSignatureFor(Action action) internal pure returns (bytes32) {
    if (action == Action.LoanRegistered) return LOAN_REGISTERED_EVENT;
    if (action == Action.LoanFunded) return LOAN_FUNDED_EVENT;
    if (action == Action.LoanRepaid) return LOAN_REPAID_EVENT;
    revert InvalidAction(uint8(action));
}

    function _dispatch(Action action, LedgerLineDecoder.LogEntry memory log) internal {
    if (action == Action.LoanRegistered) {
        // topics[0] = event signature, topics[1] = loanId, topics[2] = lender, topics[3] = borrower
        uint256 loanId = uint256(log.topics[1]);
        address borrower = address(uint160(uint256(log.topics[3])));
        (uint256 loanAmount, uint256 expectedRepayment, uint256 deadline) =
            abi.decode(log.data, (uint256, uint256, uint256));

        creditRegistry.registerLoan(
            sourceChainKey,
            loanId,
            LoanFlow({from: borrower, to: address(uint160(uint256(log.topics[2]))), withToken: address(0)}),
            LoanTerms({loanAmount: loanAmount, expectedRepaymentAmount: expectedRepayment, deadlineTimestamp: deadline})
        );
    } else if (action == Action.LoanFunded) {
        uint256 loanId = uint256(log.topics[1]);
        creditRegistry.markLoanFunded(sourceChainKey, loanId);
    } else if (action == Action.LoanRepaid) {
        uint256 loanId = uint256(log.topics[1]);
        creditRegistry.recordLoanRepayment(sourceChainKey, loanId, abi.decode(log.data, (uint256)));
    } else {
        revert InvalidAction(uint8(action));
    }

     }
}