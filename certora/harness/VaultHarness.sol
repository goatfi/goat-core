// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC4626 } from "../../dependencies/@openzeppelin-contracts-5.4.0/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "../../dependencies/@openzeppelin-contracts-5.4.0/token/ERC20/ERC20.sol";

contract VaultHarness is ERC4626 {
    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) ERC4626(asset_) ERC20(name_, symbol_) {}
}