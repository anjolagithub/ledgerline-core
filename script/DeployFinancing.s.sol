// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {LedgerLineFinancing} from "../src/LedgerLineFinancing.sol";

/// @dev Run with: forge script script/DeployFinancing.s.sol --rpc-url cc3_testnet --broadcast --legacy -vvvv
contract DeployFinancing is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");

        vm.startBroadcast(deployerKey);
        LedgerLineFinancing financing = new LedgerLineFinancing(registryAddr);
        vm.stopBroadcast();

        console.log("LedgerLineFinancing deployed:", address(financing));
        console.log("Reads credit data from registry:", registryAddr);
    }
}