// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAttestcoinProofVerifier} from "./interfaces/IAttestcoinProofVerifier.sol";
import {ILedgerLineProofVerifier} from "./interfaces/ILedgerLineProofVerifier.sol";

/// @title LedgerLineProofVerifier
/// @notice Thin, isolated wrapper around the native precompile at 0x...0FD2.
///         Kept as its own contract (rather than inlined into the manager) so the
///         precompile-facing surface can be unit-tested against a mock in isolation.
contract LedgerLineProofVerifier is ILedgerLineProofVerifier {
    /// @dev Fixed precompile address per Creditcoin's CC3 documentation —
    ///      identical on CC3 Mainnet and CC3 Testnet.
    address public constant BLOCK_PROVER_PRECOMPILE = 0x0000000000000000000000000000000000000FD2;

    error ProofVerificationFailed(uint64 chainKey, uint64 blockHeight);

    event ProofVerified(uint64 indexed chainKey, uint64 blockHeight, bool success);

    function verify(
        uint64 chainKey,
        uint64 blockHeight,
        bytes calldata encodedTransaction,
        IAttestcoinProofVerifier.MerkleProof calldata merkleProof,
        IAttestcoinProofVerifier.ContinuityProof calldata continuityProof
    ) external returns (bool) {
        bool ok = IAttestcoinProofVerifier(BLOCK_PROVER_PRECOMPILE).verifyAndEmit(
            chainKey, blockHeight, encodedTransaction, merkleProof, continuityProof
        );
        emit ProofVerified(chainKey, blockHeight, ok);
        if (!ok) revert ProofVerificationFailed(chainKey, blockHeight);
        return ok;
    }
}