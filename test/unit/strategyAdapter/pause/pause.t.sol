// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Pause_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    event Paused(address account);

    function test_RevertWhen_CallerNotGuardian() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGuardian.selector, users.bob));
        vm.prank(users.bob); strategy.pause();
    }

    modifier whenCallerGuardian() {
        _;
    }

    function test_RevertWhen_ContractPaused()
        external
        whenCallerGuardian
    {   
        // Pause the strategy
        vm.prank(users.guardian); strategy.pause();

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.guardian); strategy.pause();
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_Pause()
        external
        whenCallerGuardian
        whenContractNotPaused
    {
        // Expect the relevant event to be emitted
        vm.expectEmit({emitter: address(strategy)});
        emit Paused(users.guardian);
        
        vm.prank(users.guardian); strategy.pause();

        // Assert contract is paused
        bool actualStrategyPaused = strategy.paused();
        bool expectedStrategyPaused = true;
        assertEq(actualStrategyPaused, expectedStrategyPaused, "pause");
    }
}