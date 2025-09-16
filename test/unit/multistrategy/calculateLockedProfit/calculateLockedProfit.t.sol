// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract CalculateLockedProfit_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    MockStrategyAdapter strategy;

    function test_CalculateLockedProfit_NoFunds() external view {
        uint256 actualLockedProfit = multistrategy.calculateLockedProfit();
        uint256 expectedLockedProfit = 0;
        assertEq(actualLockedProfit, expectedLockedProfit, "calculateLockedProfit");
    }

    modifier whenWithFunds() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    modifier whenNoPreviousProfit() {
        _;
    }

    modifier whenGetsProfit() {
        if (address(strategy) == address(0)) strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);
        if (multistrategy.lockedProfit() > 0) vm.warp(block.timestamp + 1 days);
        vm.prank(users.manager); strategy.requestCredit();
        strategy.earn(10 ether);
        vm.prank(users.manager); strategy.sendReport(0);
        _;
    }

    function test_CalculateLockedProfit_WithFunds_NoPreviousProfit_GetsProfit()
        external
        whenWithFunds
        whenNoPreviousProfit
        whenGetsProfit()
    {
        uint256 actualLockedProfit = multistrategy.calculateLockedProfit();
        uint256 expectedLockedProfit = 9 ether;
        assertEq(actualLockedProfit, expectedLockedProfit, "calculateLockedProfit");
    }

    modifier whenGetsLoss() {
        if (address(strategy) == address(0)) strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);
        if (multistrategy.lockedProfit() > 0) vm.warp(block.timestamp + 1 days);
        vm.prank(users.manager); strategy.requestCredit();
        strategy.lose(1 ether);
        vm.prank(users.manager); strategy.sendReport(0);
        _;
    }

    function test_CalculateLockedProfit_WithFunds_NoPreviousProfit_GetsLoss()
        external
        whenWithFunds
        whenNoPreviousProfit
        whenGetsLoss()
    {
        uint256 actualLockedProfit = multistrategy.calculateLockedProfit();
        uint256 expectedLockedProfit = 0;
        assertEq(actualLockedProfit, expectedLockedProfit, "calculateLockedProfit");
    }

    modifier whenPreviousProfitExists() {
        strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategy.requestCredit();
        strategy.earn(10 ether);
        vm.prank(users.manager); strategy.sendReport(0);
        assertEq(multistrategy.lockedProfit(), 9 ether, "lockedProfit should be the profit");
        _;
    }

    function test_CalculateLockedProfit_WithFunds_PreviousProfit_GetsNewProfit()
        external
        whenWithFunds
        whenPreviousProfitExists
        whenGetsProfit()
    {
        uint256 previousLockedProfit = 9 ether;
        uint256 actualLockedProfit = multistrategy.calculateLockedProfit();
        uint256 expectedLockedProfit = _calculateDegradedProfit(previousLockedProfit, 1 days) + 9 ether;
        assertEq(actualLockedProfit, expectedLockedProfit, "calculateLockedProfit");
    }

    function test_CalculateLockedProfit_WithFunds_PreviousProfit_GetsLoss()
        external
        whenWithFunds
        whenPreviousProfitExists
        whenGetsLoss()
    {
        uint256 previousLockedProfit = 9 ether;
        uint256 actualLockedProfit = multistrategy.calculateLockedProfit();
        uint256 expectedLockedProfit = _calculateDegradedProfit(previousLockedProfit, 1 days) - 1 ether;
        assertEq(actualLockedProfit, expectedLockedProfit, "calculateLockedProfit");
    }

    function _calculateDegradedProfit(uint256 lockedProfit, uint256 timeElapsed) internal view returns (uint256) {
        uint256 lockedFundsRatio = timeElapsed * multistrategy.LOCKED_PROFIT_DEGRADATION();
        if (lockedFundsRatio < multistrategy.DEGRADATION_COEFFICIENT()) {
            return lockedProfit - Math.mulDiv(lockedFundsRatio, lockedProfit, multistrategy.DEGRADATION_COEFFICIENT());
        }
        return 0;
    }
}