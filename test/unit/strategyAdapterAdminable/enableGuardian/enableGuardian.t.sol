// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IStrategyAdapterAdminable } from "src/interfaces/IStrategyAdapterAdminable.sol";

contract EnableGuardian_Test is StrategyAdapter_Base_Test {

    function test_EnableGuardian_RevertWhenNotOwner() external {
        address guardian = users.guardian;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.startPrank(users.bob); strategy.enableGuardian(guardian);
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_EnableGuardian() external whenCallerIsOwner {

        vm.expectEmit(true, true, true, true, address(strategy));
        emit IStrategyAdapterAdminable.GuardianEnabled({ _guardian: users.bob });

        vm.prank(users.manager); strategy.enableGuardian(users.bob);

        bool isEnabled = strategy.guardians(users.bob);
        bool expectedToBeEnabled = true;
        assertEq(isEnabled, expectedToBeEnabled, "enable guardian");
    }
}