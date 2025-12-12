// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockAdapter } from "../../../mocks/MockAdapter.sol";

contract AvailableLiquidity_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    uint256 depositAmount = 1000 ether;
    MockAdapter strategyOne;
    MockAdapter strategyTwo;
    MockAdapter strategyThree;

    function test_AvailableLiquidity_NoDeposits() external view {
        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = 0;
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }

    modifier whenMultistrategyHasDeposits() {
        _userDeposit(users.bob, depositAmount);
        _;
    }

    function test_AvailableLiquidity_NoActiveStrategy()
        external
        whenMultistrategyHasDeposits
    {
        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = depositAmount;
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }

    modifier whenMultistrategyHasActiveStrategy() {
        strategyOne = _createAndAddAdapter(5_000, 0, 100_000 ether);
        _;
    }

    function test_AvailableLiquidity_ActiveStrategy_NoCredit()
        external
        whenMultistrategyHasDeposits
        whenMultistrategyHasActiveStrategy
    {
        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = depositAmount;
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }

    modifier whenStrategyHasRequestedCredit() {
        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    function test_AvailableLiquidity_OneStrategy_MoreLiquidityThanAssets()
        external
        whenMultistrategyHasDeposits
        whenMultistrategyHasActiveStrategy
        whenStrategyHasRequestedCredit
    {
        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = multistrategy.balance() + strategyOne.totalAssets();
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }

    function test_AvailableLiquidity_OneStrategy_LessLiquidityThanAssets()
        external
        whenMultistrategyHasDeposits
        whenMultistrategyHasActiveStrategy
        whenStrategyHasRequestedCredit
    {
        // Reduce liquidity by 100 ether.
        strategyOne.vault().borrow(100 ether);

        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = multistrategy.balance() + strategyOne.availableLiquidity();
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }

    modifier whenThereAreMultipleStrategies() {
        strategyTwo = _createAndAddAdapter(2_000, 0, 100_000 ether);
        strategyThree = _createAndAddAdapter(1_000, 0, 100_000 ether);
        vm.prank(users.manager); strategyTwo.requestCredit();
        vm.prank(users.manager); strategyThree.requestCredit();
        _;
    }

    function test_AvailableLiquidity_MultipleStrategies_AllMoreLiquidityThanAssets()
        external
        whenMultistrategyHasDeposits
        whenMultistrategyHasActiveStrategy
        whenStrategyHasRequestedCredit
        whenThereAreMultipleStrategies
    {
        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = multistrategy.balance() + strategyOne.totalAssets() + strategyTwo.totalAssets() + strategyThree.totalAssets();
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }

    function test_AvailableLiquidity_MultipleStrategies_NotAllMoreLiquidityThanAssets()
        external
        whenMultistrategyHasDeposits
        whenMultistrategyHasActiveStrategy
        whenStrategyHasRequestedCredit
        whenThereAreMultipleStrategies
    {
        strategyTwo.vault().borrow(100 ether);

        uint256 actualLiquidity = multistrategy.availableLiquidity();
        uint256 expectedLiquidity = multistrategy.balance() + strategyOne.totalAssets() + strategyTwo.availableLiquidity();
        assertEq(actualLiquidity, expectedLiquidity, "availableLiquidity");
    }
}