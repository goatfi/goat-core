// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Panic_Integration_Concrete_Test is Adapter_Base_Test {
    function test_RevertWhen_CallerNotMultistrategy() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotMultistrategy.selector, users.bob));
        vm.prank(users.bob); strategy.panic();
    }

    modifier whenCallerMultistrategy() {
        _;
    }

    function test_Panic() external whenCallerMultistrategy {
        _userDeposit(users.alice, 1_000 ether);
        vm.prank(strategy.owner()); strategy.requestCredit();
        assertGt(multistrategy.strategyTotalDebt(address(strategy)), 0, "panic, initial total debt");

        // Set the debt ratio of the strategy 0
        vm.prank(users.owner); multistrategy.setStrategyDebtRatio(address(strategy), 0);

        vm.prank(address(multistrategy)); strategy.panic();

        // Assert emergencyWithdraw has been performed
        uint256 actualStakingBalance = strategy.totalAssets();
        uint256 expectedStakingBalance = 0;
        assertEq(actualStakingBalance, expectedStakingBalance, "panic, staking balance");

        // Assert allowance to the staking contract has been revoked
        address stakingContract = address(strategy.vault());
        uint256 actualStakingAllowance = IERC20(strategy.asset()).allowance(address(strategy), stakingContract);
        uint256 expectedStakingAllowance = 0;
        assertEq(actualStakingAllowance, expectedStakingAllowance, "panic, staking allowance");

        //Assert that the strategy has reported the correct amount of assets
        assertEq(multistrategy.strategyTotalDebt(address(strategy)), 0, "panic, total debt");
    }
}
