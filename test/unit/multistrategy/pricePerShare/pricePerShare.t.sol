// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract PricePerShare_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;

    function test_PricePerShare_ZeroTotalSupply() external view {
        uint256 actualPricePerShare = multistrategy.pricePerShare();
        uint256 expectedPricePerShare = 1 ether;
        assertEq(actualPricePerShare, expectedPricePerShare, "pricePerShare");
    }

    modifier whenTotalSupplyHigherThanZero() {
        _userDeposit(users.bob, 1_000 ether);
        _;
    }

    function test_PricePerShare_NoProfit() 
        external
        whenTotalSupplyHigherThanZero
    {
        uint256 actualPricePerShare = multistrategy.pricePerShare();
        uint256 expectedPricePerShare = 1 ether;
        assertEq(actualPricePerShare, expectedPricePerShare, "pricePerShare");
    }

    modifier whenThereIsLockedProfit() {
        strategy = _createAndAddAdapter(5_000, 0, type(uint256).max);
        vm.prank(users.manager); strategy.requestCredit();
        strategy.earn(100 ether);
        _;
    }

    function test_PricePerShare_Profit()
        external
        whenTotalSupplyHigherThanZero
        whenThereIsLockedProfit
    {
        // At this point, there is no profit, so pricePerShare should be 1
        uint256 actualPricePerShare = multistrategy.pricePerShare();
        uint256 expectedPricePerShare = 1 ether;
        assertEq(actualPricePerShare, expectedPricePerShare, "pricePerShare");

        vm.prank(users.manager); strategy.sendReport(0);
        vm.warp(block.timestamp + 7 days);

        // At this point, all profit is unlocked, so price per share should be higher
        actualPricePerShare = multistrategy.pricePerShare();
        // Strategy made 10% gain, but multistrategy profit is 9,5%, as it already deducted fees.
        expectedPricePerShare = (1090 * 10 ** 15); 
        assertApproxEqAbs(actualPricePerShare, expectedPricePerShare, 1, "pricePerShare");

        // Assert that Alice has less than 1_000 ether shares
        uint256 aliceShares = multistrategy.balanceOf(users.alice);
        uint256 maxExpectedShares = 1_000 * 1e18;
        assertLt(aliceShares, maxExpectedShares, "Alice should have less than 1_000 shares");
    }
}