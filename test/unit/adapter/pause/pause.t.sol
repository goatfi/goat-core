// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Pause_Integration_Concrete_Test is Adapter_Base_Test {

    function test_RevertWhen_CallerNotGuardian() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); strategy.pause();
    }

    modifier whenCallerGuardian() {
        vm.prank(users.guardian);
        _;
    }

    function test_RevertWhen_ContractPaused()
        external
        whenCallerGuardian
    {
        strategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.guardian); strategy.pause();
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_Pause_ViaGuardian()
        external
        whenCallerGuardian
        whenContractNotPaused
    {
        // Expect the relevant event to be emitted
        vm.expectEmit({emitter: address(strategy)});
        emit Pausable.Paused(users.guardian);
        
        strategy.pause();

        // Assert allowance to the staking contract has been revoked
        address stakingContract = address(strategy.vault());
        uint256 actualStakingAllowance = IERC20(strategy.asset()).allowance(address(strategy), stakingContract);
        uint256 expectedStakingAllowance = 0;
        assertEq(actualStakingAllowance, expectedStakingAllowance, "pause, staking allowance");

        // Assert contract is paused
        bool actualStrategyPaused = strategy.paused();
        bool expectedStrategyPaused = true;
        assertEq(actualStrategyPaused, expectedStrategyPaused, "pause");
    }

    modifier whenCallerOwner {
        vm.prank(users.manager);
        _;
    }

    function test_Pause_ViaOwner()
        external
        whenCallerOwner
        whenContractNotPaused
    {
        // Expect the relevant event to be emitted
        vm.expectEmit({emitter: address(strategy)});
        emit Pausable.Paused(users.manager);
        
        strategy.pause();

        // Assert allowance to the staking contract has been revoked
        address stakingContract = address(strategy.vault());
        uint256 actualStakingAllowance = IERC20(strategy.asset()).allowance(address(strategy), stakingContract);
        uint256 expectedStakingAllowance = 0;
        assertEq(actualStakingAllowance, expectedStakingAllowance, "pause, staking allowance");

        // Assert contract is paused
        bool actualStrategyPaused = strategy.paused();
        bool expectedStrategyPaused = true;
        assertEq(actualStrategyPaused, expectedStrategyPaused, "pause");
    }
}