// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract CurrentPnL_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;
    uint256 constant MAX_BPS = 10_000;
    uint256 constant PERFORMANCE_FEE = 1000; // 10%

    // Modifier ensuring all strategies in withdrawOrder have non-zero addresses
    modifier whenAllStrategiesHaveNonZeroAddresses() {
        // Ensure withdrawOrder has no zero addresses (default or set explicitly)
        _;
    }

    // Modifier for strategies with totalDebt > 0
    modifier whenStrategiesHavePositiveDebt() {
        _userDeposit(users.bob, 1000 ether);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_CurrentPnL_WhenActiveStrategiesIsZero() external view {
        (uint256 profit, uint256 loss) = multistrategy.currentPnL();
        assertEq(profit, 0, "Profit should be 0 when no active strategies");
        assertEq(loss, 0, "Loss should be 0 when no active strategies");
    }

    modifier whenActiveStrategiesGreaterThanZero() {
        strategy = _createAndAddAdapter(5000, 100 ether, type(uint256).max);
        _;
    }

    function test_CurrentPnL_CalculatesPositivePnL()
        external
        whenActiveStrategiesGreaterThanZero
        whenAllStrategiesHaveNonZeroAddresses
        whenStrategiesHavePositiveDebt
    {
        // Create more strategies
        MockStrategyAdapter strategyTwo = _createAndAddAdapter(2000, 100 ether, 1000 ether);
        MockStrategyAdapter strategyThree = _createAndAddAdapter(3000, 100 ether, 1000 ether);
        vm.prank(users.manager); strategyTwo.requestCredit();
        vm.prank(users.manager); strategyThree.requestCredit();

        // Earn on two
        strategy.earn(100 ether);
        strategyTwo.earn(200 ether);
        strategyThree.lose(100 ether);

        (uint256 totalProfit, uint256 totalLoss) = multistrategy.currentPnL();
        uint256 expectedProfit1 = 100 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        uint256 expectedProfit2 = 200 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        uint256 expectedLoss3 = 100 ether;
        uint256 expectedTotalProfit = expectedProfit1 + expectedProfit2 - expectedLoss3;
        assertEq(totalProfit, expectedTotalProfit, "Total profit should be sum of calculated profits");
        assertEq(totalLoss, 0, "Total loss should be 0");
    }

    function test_CurrentPnL_CalculatesNegativePnL()
        external
        whenActiveStrategiesGreaterThanZero
        whenAllStrategiesHaveNonZeroAddresses
        whenStrategiesHavePositiveDebt
    {
        // Create more strategies
        MockStrategyAdapter strategyTwo = _createAndAddAdapter(2000, 100 ether, 1000 ether);
        MockStrategyAdapter strategyThree = _createAndAddAdapter(3000, 100 ether, 1000 ether);
        vm.prank(users.manager); strategyTwo.requestCredit();
        vm.prank(users.manager); strategyThree.requestCredit();

        // Earn on two
        strategy.earn(100 ether);
        strategyTwo.lose(100 ether);
        strategyThree.lose(100 ether);

        (uint256 totalProfit, uint256 totalLoss) = multistrategy.currentPnL();
        uint256 expectedProfit1 = 100 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        uint256 expectedLoss2 = 100 ether;
        uint256 expectedLoss3 = 100 ether;
        uint256 expectedTotalLoss = expectedLoss2 + expectedLoss3 - expectedProfit1;
        assertEq(totalProfit, 0, "Total profit should be 0");
        assertEq(totalLoss, expectedTotalLoss, "Total loss should be the sum of gains and losses");
    }
}