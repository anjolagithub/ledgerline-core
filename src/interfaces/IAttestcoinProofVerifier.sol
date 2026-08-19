// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IAttestcoinProofVerifier
/// @notice Interface matching Creditcoin's native BlockProver precompile (address 0x...0FD2),
///         known internally as the Native Query Verifier. Struct shapes and the
///         verifyAndEmit() signature are fixed by the precompile — not open to redesign.
///         Source: docs.creditcoin.org/attestcoin-protocol/dapp-builder-infrastructure/attestcoin-smart-contracts
interface IAttestcoinProofVerifier {
    struct MerkleProofEntry {
        bytes32 hash;
        bool isLeft;
    }

    struct MerkleProof {
        bytes32 root;
        MerkleProofEntry[] siblings;
    }

    struct ContinuityProof {
        bytes32 lowerEndpointDigest;
        bytes32[] roots;
    }

    /// @notice Synchronously verifies a transaction's Merkle inclusion proof and its
    ///         continuity proof (that the containing block chains back to an attestation
    ///         point on Creditcoin). Reverts on failure rather than returning false silently
    ///         in the precompile's own semantics, but we treat the boolean as authoritative
    ///         at the ABI boundary per the documented signature.
    /// @param chainKey Creditcoin-internal source chain identifier (NOT the EVM chainId).
    /// @param blockHeight Block number on the source chain containing the transaction.
    /// @param encodedTransaction ABI-encoded transaction + receipt bytes from the source chain.
    /// @param merkleProof Inclusion proof: root + sibling path.
    /// @param continuityProof Chain-of-roots proof anchoring the block to an attestation.
    function verifyAndEmit(
        uint64 chainKey,
        uint64 blockHeight,
        bytes calldata encodedTransaction,
        MerkleProof calldata merkleProof,
        ContinuityProof calldata continuityProof
    ) external returns (bool verified);
}