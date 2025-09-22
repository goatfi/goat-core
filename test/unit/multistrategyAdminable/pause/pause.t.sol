// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Pause_Integration_Concrete_Test is Multistrategy_Base_Test {
    event Paused(address account);

    function test_RevertWhen_CallerNotGuardian() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.pause();
    }

    modifier whenCallerIsGuardian() {
        _;
    }

    function test_RevertWhen_ContractIsPaused() external whenCallerIsGuardian {
        // Pause the contract so we can test the revert.
        vm.prank(users.guardian); multistrategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.guardian); multistrategy.pause();
    }

    modifier whenContractIsUnpaused() {
        _;
    }

    function test_Pause() 
        external 
        whenCallerIsGuardian 
        whenContractIsUnpaused 
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit Paused({ account: users.guardian });

        vm.prank(users.guardian); multistrategy.pause();

        // Assert that the contract has been paused.
        bool isPaused = multistrategy.paused();
        bool expectedToBePaused = true;
        assertEq(isPaused, expectedToBePaused, "pause");
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevertWhen_ContractIsPaused_ViaOwner() external whenCallerIsOwner {
        // Pause the contract so we can test the revert.
        vm.prank(users.owner); multistrategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.owner); multistrategy.pause();
    }

    function test_Pause_ViaOwner() 
        external 
        whenCallerIsOwner 
        whenContractIsUnpaused 
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit Paused({ account: users.owner });

        // Pause the contract.
        vm.prank(users.owner); multistrategy.pause();

        // Assert that the contract has been paused.
        bool isPaused = multistrategy.paused();
        bool expectedToBePaused = true;
        assertEq(isPaused, expectedToBePaused, "pause");
    }
}