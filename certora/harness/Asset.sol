// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC20 } from "../../dependencies/@openzeppelin-contracts-5.4.0/token/ERC20/ERC20.sol";

contract Asset is ERC20 {
    constructor() ERC20("Asset", "A"){}
}