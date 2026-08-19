// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {LedgerLineReadabilityManager} from "../src/LedgerLineReadabilityManager.sol";
import {LedgerLineRegistry} from "../src/LedgerLineRegistry.sol";
import {MockLedgerLineProofVerifier} from "./mocks/MockLedgerLineProofVerifier.sol";
import {IAttestcoinProofVerifier} from "../src/interfaces/IAttestcoinProofVerifier.sol";
import {LedgerLineDecoder} from "../src/lib/LedgerLineDecoder.sol";
import {LoanOrder} from "../src/LedgerLineTypes.sol";

contract LedgerLineReadabilityManagerTest is Test {
    LedgerLineReadabilityManager manager;
    LedgerLineRegistry registry;
    MockLedgerLineProofVerifier mockVerifier;

    address admin = address(this);
    bytes32 sourceChainKey = bytes32(uint256(1));
    address sourceRegistryAddr = address(0xAAA1);
    address sourceSettlementAddr = address(0xAAA2);

    address lender = address(0x1E4D);
    address borrower = address(0xB0B);

    function setUp() public {
        registry = new LedgerLineRegistry(admin);
        mockVerifier = new MockLedgerLineProofVerifier();
        manager = new LedgerLineReadabilityManager(address(registry), address(mockVerifier), admin);

        registry.grantRole(registry.READABILITY_ROLE(), address(manager));
        manager.configureSourceChain(sourceChainKey, sourceRegistryAddr, sourceSettlementAddr);
    }

    function _emptyProof()
        internal
        pure
        returns (IAttestcoinProofVerifier.MerkleProof memory, IAttestcoinProofVerifier.ContinuityProof memory)
    {
        IAttestcoinProofVerifier.MerkleProofEntry[] memory siblings = new IAttestcoinProofVerifier.MerkleProofEntry[](0);
        bytes32[] memory roots = new bytes32[](0);
        return (
            IAttestcoinProofVerifier.MerkleProof({root: bytes32(0), siblings: siblings}),
            IAttestcoinProofVerifier.ContinuityProof({lowerEndpointDigest: bytes32(0), roots: roots})
        );
    }

    /// @dev Builds a realistic encodedTransaction matching LedgerLineDecoder's expected
    ///      format: abi.encode(uint8 txType, bytes[] chunks), with a single log entry
    ///      injected into the receipt chunk.
    function _buildEncodedTx(LedgerLineDecoder.LogEntry[] memory logs, uint8 status)
        internal
        pure
        returns (bytes memory)
    {
        bytes[] memory chunks = new bytes[](3); // txType 0 (legacy) => 3 chunks
        chunks[0] = hex"00"; // common tx fields — unused by our decoder, dummy is fine
        chunks[1] = hex"00"; // type-specific fields — unused by our decoder, dummy is fine
        chunks[2] = abi.encode(status, uint64(21000), logs, bytes("")); // receipt chunk
        return abi.encode(uint8(0), chunks);
    }

    function _loanRegisteredLog(uint256 loanId, uint256 amount, uint256 expected, uint256 deadline)
        internal
        view
        returns (LedgerLineDecoder.LogEntry[] memory)
    {
        bytes32[] memory topics = new bytes32[](4);
        topics[0] = manager.LOAN_REGISTERED_EVENT();
        topics[1] = bytes32(loanId);
        topics[2] = bytes32(uint256(uint160(lender)));
        topics[3] = bytes32(uint256(uint160(borrower)));

        LedgerLineDecoder.LogEntry[] memory logs = new LedgerLineDecoder.LogEntry[](1);
        logs[0] = LedgerLineDecoder.LogEntry({
            emitter: sourceRegistryAddr,
            topics: topics,
            data: abi.encode(amount, expected, deadline)
        });
        return logs;
    }

    function _loanRepaidLog(uint256 loanId, uint256 amount)
        internal
        view
        returns (LedgerLineDecoder.LogEntry[] memory)
    {
        bytes32[] memory topics = new bytes32[](2);
        topics[0] = manager.LOAN_REPAID_EVENT();
        topics[1] = bytes32(loanId);

        LedgerLineDecoder.LogEntry[] memory logs = new LedgerLineDecoder.LogEntry[](1);
        logs[0] = LedgerLineDecoder.LogEntry({
            emitter: sourceSettlementAddr,
            topics: topics,
            data: abi.encode(amount)
        });
        return logs;
    }

    function test_SubmitProof_RegistersLoan() public {
        (IAttestcoinProofVerifier.MerkleProof memory mp, IAttestcoinProofVerifier.ContinuityProof memory cp) = _emptyProof();
        bytes memory encodedTx = _buildEncodedTx(
            _loanRegisteredLog(1, 1000 ether, 1100 ether, block.timestamp + 30 days), 1
        );

        manager.submitProof(0, 1, encodedTx, mp, cp);

        LoanOrder memory loan = registry.getLoanOrder(sourceChainKey, 1);
        assertEq(uint8(loan.status), 0); // Created
        assertEq(loan.repayFlow.from, borrower);
        assertEq(loan.terms.loanAmount, 1000 ether);
    }

    function test_RevertWhen_ProofFails() public {
        mockVerifier.setShouldVerify(false);
        (IAttestcoinProofVerifier.MerkleProof memory mp, IAttestcoinProofVerifier.ContinuityProof memory cp) = _emptyProof();
        bytes memory encodedTx = _buildEncodedTx(_loanRegisteredLog(1, 1 ether, 1 ether, block.timestamp + 1), 1);

        vm.expectRevert();
        manager.submitProof(0, 1, encodedTx, mp, cp);
    }

    function test_RevertWhen_TransactionStatusFailed() public {
        (IAttestcoinProofVerifier.MerkleProof memory mp, IAttestcoinProofVerifier.ContinuityProof memory cp) = _emptyProof();
        // status = 0 means the source-chain transaction itself failed — must be rejected
        bytes memory encodedTx = _buildEncodedTx(_loanRegisteredLog(1, 1 ether, 1 ether, block.timestamp + 1), 0);

        vm.expectRevert(LedgerLineReadabilityManager.TransactionDidNotSucceed.selector);
        manager.submitProof(0, 1, encodedTx, mp, cp);
    }

    function test_RevertWhen_EmitterUnauthorized() public {
        (IAttestcoinProofVerifier.MerkleProof memory mp, IAttestcoinProofVerifier.ContinuityProof memory cp) = _emptyProof();
        LedgerLineDecoder.LogEntry[] memory logs = _loanRegisteredLog(1, 1 ether, 1 ether, block.timestamp + 1);
        logs[0].emitter = address(0xBADBAD); // log claims to come from an unrecognized contract

        bytes memory encodedTx = _buildEncodedTx(logs, 1);

        vm.expectRevert();
        manager.submitProof(0, 1, encodedTx, mp, cp);
    }

    function test_RevertWhen_ReplayingSameQuery() public {
        (IAttestcoinProofVerifier.MerkleProof memory mp, IAttestcoinProofVerifier.ContinuityProof memory cp) = _emptyProof();
        bytes memory encodedTx = _buildEncodedTx(
            _loanRegisteredLog(1, 1000 ether, 1100 ether, block.timestamp + 30 days), 1
        );

        manager.submitProof(0, 1, encodedTx, mp, cp);
        vm.expectRevert();
        manager.submitProof(0, 1, encodedTx, mp, cp);
    }

    function test_SubmitProof_RecordsRepayment() public {
        (IAttestcoinProofVerifier.MerkleProof memory mp, IAttestcoinProofVerifier.ContinuityProof memory cp) = _emptyProof();

        // First register the loan so repayment has something valid to apply to.
        manager.submitProof(0, 1, _buildEncodedTx(_loanRegisteredLog(1, 1000 ether, 1100 ether, block.timestamp + 30 days), 1), mp, cp);
        registry.markLoanFunded(sourceChainKey, 1); // simulate funding directly for this test

        bytes memory repayTx = _buildEncodedTx(_loanRepaidLog(1, 1100 ether), 1);
        manager.submitProof(2, 2, repayTx, mp, cp); // action=2 => LoanRepaid

        LoanOrder memory loan = registry.getLoanOrder(sourceChainKey, 1);
        assertEq(uint8(loan.status), 3); // Repaid
    }
}