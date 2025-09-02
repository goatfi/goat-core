// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { MockERC20 } from "../../../mocks/MockERC20.sol";
import { Multistrategy } from "src/Multistrategy.sol";
import { MStrat } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategy } from "interfaces/IMultistrategy.sol";
import { IStrategyAdapter } from "interfaces/IStrategyAdapter.sol";

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
        vm.prank(address(strategy)); multistrategy.requestCredit();
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

    modifier whenWithdrawOrderHasZeroAddress() {
        address[] memory newOrder = new address[](10);
        newOrder[0] = address(strategy);
        newOrder[1] = address(0);
        vm.prank(users.manager); multistrategy.setWithdrawOrder(newOrder);
        _;
    }

    function test_CurrentPnL_WhenWithdrawOrderHasZeroAddress()
        external
        whenActiveStrategiesGreaterThanZero
        whenWithdrawOrderHasZeroAddress
    {
        // Deposit and earn to set up profit
        _userDeposit(users.bob, 1000 ether);
        vm.prank(users.manager); uint256 creditRequested = strategy.requestCredit();
        assertGt(creditRequested, 0);
        strategy.earn(100 ether);

        (uint256 profit, uint256 loss) = multistrategy.currentPnL();
        uint256 expectedProfit = 100 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        assertEq(profit, expectedProfit, "Profit should include only strategies before zero address");
        assertEq(loss, 0, "Loss should be 0");
    }

    function test_CurrentPnL_WhenStrategyHasZeroDebt_ContinuesToNextStrategy()
        external
        whenActiveStrategiesGreaterThanZero
        whenAllStrategiesHaveNonZeroAddresses
    {
        // Create second strategy with zero debt
        _createAndAddAdapter(2000, 100 ether, 1000 ether);
        _userDeposit(users.bob, 1000 ether);

        // Only first strategy requests credit (totalDebt > 0)
        vm.prank(users.manager); strategy.requestCredit();
        strategy.earn(100 ether);

        (uint256 profit, uint256 loss) = multistrategy.currentPnL();
        uint256 expectedProfit = 100 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        assertEq(profit, expectedProfit, "Profit should only include strategy with debt");
        assertEq(loss, 0, "Loss should be 0");
    }

    function test_CurrentPnL_WhenCurrentPnLCallReverts_Reverts()
        external
        whenActiveStrategiesGreaterThanZero
        whenAllStrategiesHaveNonZeroAddresses
        whenStrategiesHavePositiveDebt
    {
        // Mock currentPnL to revert
        vm.mockCallRevert(
            address(strategy),
            abi.encodeWithSelector(IStrategyAdapter.currentPnL.selector),
            "Mock revert"
        );

        vm.expectRevert("Mock revert");
        multistrategy.currentPnL();
    }

    function test_CurrentPnL_WhenCurrentPnLSucceeds_CalculatesAndAccumulatesProfitLoss()
        external
        whenActiveStrategiesGreaterThanZero
        whenAllStrategiesHaveNonZeroAddresses
        whenStrategiesHavePositiveDebt
    {
        // Create second strategy
        MockStrategyAdapter strategy2 = _createAndAddAdapter(2000, 100 ether, 1000 ether);
        vm.prank(address(strategy2)); multistrategy.requestCredit();

        // Earn on both
        strategy.earn(100 ether);
        strategy2.earn(200 ether);

        (uint256 totalProfit, uint256 totalLoss) = multistrategy.currentPnL();
        uint256 expectedProfit1 = 100 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        uint256 expectedProfit2 = 200 ether * (MAX_BPS - PERFORMANCE_FEE) / MAX_BPS;
        uint256 expectedTotalProfit = expectedProfit1 + expectedProfit2;
        assertEq(totalProfit, expectedTotalProfit, "Total profit should be sum of calculated profits");
        assertEq(totalLoss, 0, "Total loss should be 0");
    }
}