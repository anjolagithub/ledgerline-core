// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice A minimal, publicly-mintable ERC20 for demo purposes only — lets anyone
///         mint themselves demo funds on Sepolia without needing a real stablecoin
///         faucet. Not used anywhere in the core LedgerLine credit-scoring logic.
contract DemoUSD is ERC20 {
    constructor() ERC20("LedgerLine Demo USD", "dUSD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
