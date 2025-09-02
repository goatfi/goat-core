// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { IMultistrategyAdminable } from "interfaces/IMultistrategyAdminable.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

contract RevokeGuardian_Integration_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.revokeGuardian(users.bob);
    }

    modifier whenCallerOwner() {
        vm.prank(users.owner);
        _;
    }

    /// @dev Already revoked also means that hasn't been enabled
    function test_RevokeGuardian_AlreadyRevokedGuardian() external whenCallerOwner {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.GuardianRevoked({ _guardian: users.alice });

        // Enable the guardian
        multistrategy.revokeGuardian(users.alice);

        // Assert the guardian has been revoked
        bool isEnabled = multistrategy.guardians(users.alice);
        bool expectedToBeEnabled = false;
        assertEq(isEnabled, expectedToBeEnabled, "revoke guardian");
    }

    function test_RevokeGuardian_ZeroAddress() external whenCallerOwner {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.GuardianRevoked({ _guardian: address(0) });

        // Enable the guardian
        multistrategy.revokeGuardian(address(0));

        // Assert the address(0) has been revoked
        bool isEnabled = multistrategy.guardians(address(0));
        bool expectedToBeEnabled = false;
        assertEq(isEnabled, expectedToBeEnabled, "revoke guardian");
    }

    modifier whenNotZeroAddress() {
        _;
    }

    function test_RevokeGuardian_EnabledGuardian() 
        external 
        whenCallerOwner 
        whenNotZeroAddress
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.GuardianRevoked({ _guardian: users.guardian });

        // Enable the guardian
        multistrategy.revokeGuardian(users.guardian);

        // Assert the address(0) has been enabled
        bool isEnabled = multistrategy.guardians(users.guardian);
        bool expectedToBeEnabled = false;
        assertEq(isEnabled, expectedToBeEnabled, "revoke guardian");
    }
}