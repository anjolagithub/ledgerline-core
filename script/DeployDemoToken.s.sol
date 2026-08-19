// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {DemoUSD} from "../src/DemoUSD.sol";

/// @dev Run with: forge script script/DeployDemoToken.s.sol --rpc-url sepolia --broadcast --legacy -vvvv
contract DeployDemoToken is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        DemoUSD token = new DemoUSD();
        vm.stopBroadcast();
        console.log("DemoUSD deployed:", address(token));
        console.log("Add this to .env as DEMO_TOKEN_ADDRESS");
    }
}
