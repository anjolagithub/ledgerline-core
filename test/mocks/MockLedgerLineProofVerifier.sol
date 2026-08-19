// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILedgerLineProofVerifier} from "../../src/interfaces/ILedgerLineProofVerifier.sol";
import {IAttestcoinProofVerifier} from "../../src/interfaces/IAttestcoinProofVerifier.sol";

contract MockLedgerLineProofVerifier is ILedgerLineProofVerifier {
    bool public shouldVerify = true;

    function setShouldVerify(bool value) external {
        shouldVerify = value;
    }

    function verify(
        uint64,
        uint64,
        bytes calldata,
        IAttestcoinProofVerifier.MerkleProof calldata,
        IAttestcoinProofVerifier.ContinuityProof calldata
    ) external view override returns (bool) {
        return shouldVerify;
    }
}