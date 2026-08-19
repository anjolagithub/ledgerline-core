// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LedgerLineRegistry} from "../src/LedgerLineRegistry.sol";
import {LedgerLineProofVerifier} from "../src/LedgerLineProofVerifier.sol";
import {LedgerLineReadabilityManager} from "../src/LedgerLineReadabilityManager.sol";

/// @notice Deploys LedgerLine's hub-chain contracts to Creditcoin CC3 Testnet, and
///         wires them together: grants the manager write access to the registry,
///         and configures the manager to trust the already-deployed Sepolia contracts.
/// @dev Run with: forge script script/DeployHub.s.sol --rpc-url cc3_testnet --broadcast
///      Requires SOURCE_REGISTRY_ADDRESS and SOURCE_SETTLEMENT_ADDRESS in .env,
///      copied from the DeploySource.s.sol output.
contract DeployHub is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        uint256 sourceChainKeyRaw = vm.envUint("SOURCE_CHAIN_KEY");
        address sourceRegistryAddr = vm.envAddress("SOURCE_REGISTRY_ADDRESS");
        address sourceSettlementAddr = vm.envAddress("SOURCE_SETTLEMENT_ADDRESS");

        vm.startBroadcast(deployerKey);

        LedgerLineRegistry registry = new LedgerLineRegistry(deployer);
        LedgerLineProofVerifier proofVerifier = new LedgerLineProofVerifier();
        LedgerLineReadabilityManager manager = new LedgerLineReadabilityManager(
            address(registry),
            address(proofVerifier),
            deployer
        );

        // Grant the manager write access to the scoring registry.
        registry.grantRole(registry.READABILITY_ROLE(), address(manager));

        // Bind this hub instance to exactly one source chain, fail-closed.
        bytes32 sourceChainKey = bytes32(sourceChainKeyRaw);
        manager.configureSourceChain(sourceChainKey, sourceRegistryAddr, sourceSettlementAddr);

        vm.stopBroadcast();

        console.log("=== LedgerLine Hub-Chain Deployment (Creditcoin CC3 Testnet) ===");
        console.log("Deployer:                        ", deployer);
        console.log("LedgerLineRegistry:              ", address(registry));
        console.log("LedgerLineProofVerifier:         ", address(proofVerifier));
        console.log("LedgerLineReadabilityManager:    ", address(manager));
        console.log("Bound to source chain key:       ", sourceChainKeyRaw);
        console.log("Trusting source registry:        ", sourceRegistryAddr);
        console.log("Trusting source settlement:      ", sourceSettlementAddr);
    }
}