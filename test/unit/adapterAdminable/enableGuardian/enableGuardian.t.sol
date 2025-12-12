// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IAdapterAdminable } from "src/interfaces/IAdapterAdminable.sol";

contract EnableGuardian_Test is Adapter_Base_Test {

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
        emit IAdapterAdminable.GuardianEnabled({ _guardian: users.bob });

        vm.prank(users.manager); strategy.enableGuardian(users.bob);

        bool isEnabled = strategy.guardians(users.bob);
        bool expectedToBeEnabled = true;
        assertEq(isEnabled, expectedToBeEnabled, "enable guardian");
    }
}