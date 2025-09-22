// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { IMultistrategyAdminable } from "interfaces/IMultistrategyAdminable.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract RevokeGuardian_Integration_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.revokeGuardian(users.bob);
    }

    modifier whenCallerOwner() {
        _;
    }

    function test_RevokeGuardian() external whenCallerOwner {
        // Enable alice as guardian and check that it has been enabled
        vm.prank(users.owner); multistrategy.enableGuardian(users.alice);
        assertEq(multistrategy.guardians(users.alice), true, "alice not enabled as guardian");

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.GuardianRevoked({ _guardian: users.alice });

        vm.prank(users.owner); multistrategy.revokeGuardian(users.alice);

        bool isEnabled = multistrategy.guardians(users.alice);
        bool expectedToBeEnabled = false;
        assertEq(isEnabled, expectedToBeEnabled, "revoke guardian");
    }
}