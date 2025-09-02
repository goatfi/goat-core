// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Panic_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotGuardian() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGuardian.selector, users.bob));
        vm.prank(users.bob); strategy.panic();
    }

    modifier whenCallerGuardian() {
        _;
    }

    function test_Panic() external whenCallerGuardian {
        vm.prank(users.guardian); strategy.panic();

        // Assert emergencyWithdraw has been performed
        uint256 actualStakingBalance = strategy.totalAssets();
        uint256 expectedStakingBalance = 0;
        assertEq(actualStakingBalance, expectedStakingBalance, "panic, staking balance");

        // Assert allowance to the staking contract has been revoked
        address stakingContract = address(strategy.vault());
        uint256 actualStakingAllowance = IERC20(strategy.asset()).allowance(address(strategy), stakingContract);
        uint256 expectedStakingAllowance = 0;
        assertEq(actualStakingAllowance, expectedStakingAllowance, "panic, staking allowance");

        // Assert the contract has been paused
        bool actualContractPaused = strategy.paused();
        bool expectedContractPaused = true;
        assertEq(actualContractPaused, expectedContractPaused, "panic, contract paused");
    }
}