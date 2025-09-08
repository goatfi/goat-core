// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { IMultistrategyAdminable } from "interfaces/IMultistrategyAdminable.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract EnableGuardian_Integration_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.enableGuardian(users.bob);
    }

    modifier whenCallerOwner() {
        _;
    }

    function test_EnableGuardian() external whenCallerOwner
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.GuardianEnabled({ _guardian: users.bob });

        vm.prank(users.owner); multistrategy.enableGuardian(users.bob);

        bool isEnabled = multistrategy.guardians(users.bob);
        bool expectedToBeEnabled = true;
        assertEq(isEnabled, expectedToBeEnabled, "enable guardian");
    }
}