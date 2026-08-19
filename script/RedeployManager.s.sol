// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LedgerLineRegistry} from "../src/LedgerLineRegistry.sol";
import {LedgerLineReadabilityManager} from "../src/LedgerLineReadabilityManager.sol";

/// @notice Redeploys ONLY LedgerLineReadabilityManager (its interface changed —
///         real log decoding replaced the old pre-decoded-payload design).
///         Reuses the already-deployed LedgerLineRegistry and LedgerLineProofVerifier.
/// @dev Run with: forge script script/RedeployManager.s.sol --rpc-url cc3_testnet --broadcast --legacy -vvvv
///      Requires in .env: REGISTRY_ADDRESS, PROOF_VERIFIER_ADDRESS (existing deployments),
///      SOURCE_CHAIN_KEY, SOURCE_REGISTRY_ADDRESS, SOURCE_SETTLEMENT_ADDRESS.
///      Optionally: OLD_MANAGER_ADDRESS, to revoke its role.
contract RedeployManager is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");
        address proofVerifierAddr = vm.envAddress("PROOF_VERIFIER_ADDRESS");
        uint256 sourceChainKeyRaw = vm.envUint("SOURCE_CHAIN_KEY");
        address sourceRegistryAddr = vm.envAddress("SOURCE_REGISTRY_ADDRESS");
        address sourceSettlementAddr = vm.envAddress("SOURCE_SETTLEMENT_ADDRESS");
        address oldManager = vm.envOr("OLD_MANAGER_ADDRESS", address(0));

        LedgerLineRegistry registry = LedgerLineRegistry(registryAddr);

        vm.startBroadcast(deployerKey);

        LedgerLineReadabilityManager newManager = new LedgerLineReadabilityManager(
            registryAddr,
            proofVerifierAddr,
            deployer
        );

        registry.grantRole(registry.READABILITY_ROLE(), address(newManager));

        bytes32 sourceChainKey = bytes32(sourceChainKeyRaw);
        newManager.configureSourceChain(sourceChainKey, sourceRegistryAddr, sourceSettlementAddr);

        if (oldManager != address(0)) {
            registry.revokeRole(registry.READABILITY_ROLE(), oldManager);
        }

        vm.stopBroadcast();

        console.log("=== LedgerLine Manager Redeployment (CC3 Testnet) ===");
        console.log("New LedgerLineReadabilityManager:", address(newManager));
        console.log("Reused registry:                 ", registryAddr);
        console.log("Reused proof verifier:            ", proofVerifierAddr);
        if (oldManager != address(0)) {
            console.log("Old manager role revoked:        ", oldManager);
        }
        console.log("Update your relayer scripts and .env with this new manager address.");
    }
}
