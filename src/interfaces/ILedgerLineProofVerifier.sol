// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAttestcoinProofVerifier} from "./IAttestcoinProofVerifier.sol";

/// @notice Interface the manager depends on, instead of the concrete
///         LedgerLineProofVerifier — lets tests substitute a mock instead of
///         reaching the real precompile, which doesn't exist in a local EVM.
interface ILedgerLineProofVerifier {
    function verify(
        uint64 chainKey,
        uint64 blockHeight,
        bytes calldata encodedTransaction,
        IAttestcoinProofVerifier.MerkleProof calldata merkleProof,
        IAttestcoinProofVerifier.ContinuityProof calldata continuityProof
    ) external returns (bool);
}