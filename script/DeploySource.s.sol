// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LedgerLineSourceRegistry} from "../src/LedgerLineSourceRegistry.sol";
import {LedgerLineSourceSettlement} from "../src/LedgerLineSourceSettlement.sol";

/// @notice Deploys LedgerLine's source-chain contracts to Ethereum Sepolia.
/// @dev Run with: forge script script/DeploySource.s.sol --rpc-url sepolia --broadcast --verify
contract DeploySource is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        address lender = vm.envOr("LENDER_ADDRESS", deployer); // defaults to deployer if unset

        vm.startBroadcast(deployerKey);

        LedgerLineSourceRegistry registry = new LedgerLineSourceRegistry(deployer);
        LedgerLineSourceSettlement settlement = new LedgerLineSourceSettlement();

        // Approve the first lender so the demo flow has somewhere to start.
        registry.approveLender(lender);

        vm.stopBroadcast();

        console.log("=== LedgerLine Source-Chain Deployment (Sepolia) ===");
        console.log("Deployer:                  ", deployer);
        console.log("LedgerLineSourceRegistry:  ", address(registry));
        console.log("LedgerLineSourceSettlement:", address(settlement));
        console.log("Approved lender:           ", lender);
        console.log("");
        console.log("Copy these two addresses into .env as SOURCE_REGISTRY_ADDRESS");
        console.log("and SOURCE_SETTLEMENT_ADDRESS before running DeployHub.s.sol");
    }
}