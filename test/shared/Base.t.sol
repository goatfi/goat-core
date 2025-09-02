// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Test } from "forge-std/src/Test.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

struct Users {
    address payable owner;
    address payable manager;
    address payable guardian;
    address payable feeRecipient;
    address payable alice;
    address payable bob;
}

abstract contract Base_Test is Test {
    MockERC20 internal dai;
    Users internal users;

    uint256 assetDecimals = 18;

    function setUp() public virtual {
        dai = new MockERC20("Dai Stablecoin", "DAI");

        vm.label({ account: address(dai), newLabel: "DAI" });

        users = Users({
            owner: createUser("Owner"),
            manager: createUser("Manager"),
            guardian: createUser("Guardian"),
            feeRecipient: createUser("FeeRecipient"),
            alice: createUser("Alice"),
            bob: createUser("Bob")
        });
    }

    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        vm.label({ account: address(user), newLabel: name });
        return user;
    }

    function deployMultistrategy() internal virtual {}

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public virtual {}
}