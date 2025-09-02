// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { IMultistrategyAdminable } from "interfaces/IMultistrategyAdminable.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Errors } from "src/libraries/Errors.sol";

/// @dev By default, the caller of these functions is the owner of the Multistrategy unless specified
/// by calling swapCaller.
contract SetManager_Integration_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.setManager(users.bob);
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.owner);
        _;
    }

    function test_RevertWhen_ZeroAddress() 
        external
        whenCallerIsOwner
    {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        multistrategy.setManager(address(0));
    }

    modifier whenNotZeroAddress() {
        _;
    }

    function test_SetManager_SameManager() 
        external 
        whenCallerIsOwner 
        whenNotZeroAddress 
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.ManagerSet({ _manager: users.manager });

        // Set the manager
        multistrategy.setManager(users.manager);

        // Assert the manager has been set
        address actualManager = multistrategy.manager();
        address expectedManager = users.manager;
        assertEq(actualManager, expectedManager, "manager");
    }

    function test_SetManager_NewManager() 
        external 
        whenCallerIsOwner 
        whenNotZeroAddress 
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyAdminable.ManagerSet({ _manager: users.bob });

        // Set the manager
        multistrategy.setManager(users.bob);

        // Assert the manager has been set
        address actualManager = multistrategy.manager();
        address expectedManager = users.bob;
        assertEq(actualManager, expectedManager, "manager");
    }
}