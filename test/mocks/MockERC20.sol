// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

interface IMockERC20 {
    function mint(address to, uint256 value) external;
    function burn(address to, uint256 value) external;
}

contract MockERC20 is IMockERC20, ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() virtual public {}
}