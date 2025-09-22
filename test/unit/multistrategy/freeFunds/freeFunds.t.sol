// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract FreeFunds_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    MockStrategyAdapter strategy;

    function test_FreeFunds_ZeroTotalAssets() external view {
        // Assert that free funds is zero when total Assets is zero
        uint256 actualFreeFunds = multistrategy.freeFunds();
        uint256 expectedFreeFunds = 0;
        assertEq(actualFreeFunds, expectedFreeFunds, "freeFunds");
    }

    modifier whenTotalAssetsNotZero() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    function test_FreeFunds_ZeroLockedProfit() 
        external
        whenTotalAssetsNotZero
    {
        uint256 totalAssets = multistrategy.totalAssets();

        // Assert that free funds is totalAssets when locked profit is 0
        uint256 actualFreeFunds = multistrategy.freeFunds();
        uint256 expectedFreeFunds = totalAssets;
        assertEq(actualFreeFunds, expectedFreeFunds, "freeFunds");
    }

    modifier whenLockedProfitNotZero() {
        strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);

        vm.prank(users.manager); strategy.requestCredit();
        strategy.earn(1 ether);
        vm.prank(users.manager); strategy.sendReport(0);
        _;
    }

    function test_FreeFunds()
        external
        whenTotalAssetsNotZero
        whenLockedProfitNotZero 
    {
        uint256 totalAssets = multistrategy.totalAssets();
        uint256 lockedProfit = multistrategy.calculateLockedProfit();

        // Assert that free funds is totalAssets minus locked profit
        uint256 actualFreeFunds = multistrategy.freeFunds();
        uint256 expectedFreeFunds = totalAssets - lockedProfit;
        assertEq(actualFreeFunds, expectedFreeFunds, "freeFunds");
    }
}