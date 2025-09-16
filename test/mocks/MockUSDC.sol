// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MockERC20 } from "./MockERC20.sol";

contract MockUSDC is MockERC20 {
    constructor() MockERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}