// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";

contract CalculateGainAndLoss_Integration_Concrete_Test is StrategyAdapter_Base_Test {

    uint256 currentAssets = 0;
    uint256 totalDebt = 0;

    function test_CalculateGainAndLoss_CurrentAssetsZero_TotalDebtZero()
        external view
    {
        (uint256 actualGain, uint256 actualLoss) = strategy.calculateGainAndLoss(currentAssets);
        (uint256 expectedGain, uint256 expectedLoss) = (0, 0);
        assertEq(actualGain, expectedGain);
        assertEq(actualLoss, expectedLoss);
    }

    modifier whenTotalDebtNotZero() {
        _requestCredit(1000 ether);
        _;
    }

    function test_CalculateGainAndLoss_CurrentAssetsZero()
        external
        whenTotalDebtNotZero
    {
        totalDebt = multistrategy.strategyTotalDebt(address(strategy));

        (uint256 actualGain, uint256 actualLoss) = strategy.calculateGainAndLoss(currentAssets);
        (uint256 expectedGain, uint256 expectedLoss) = (0, totalDebt);
        assertEq(actualGain, expectedGain);
        assertEq(actualLoss, expectedLoss);
    }

    modifier whenCurrentAssetsNotZero() {
        currentAssets = 1000 ether;
        _;
    }

    function test_CalculateGainAndLoss_TotalDebtZero()
        external
        whenCurrentAssetsNotZero
    {
        (uint256 actualGain, uint256 actualLoss) = strategy.calculateGainAndLoss(currentAssets);
        (uint256 expectedGain, uint256 expectedLoss) = (currentAssets, 0);
        assertEq(actualGain, expectedGain);
        assertEq(actualLoss, expectedLoss);
    }

    function test_CalculateGainAndLoss_CurrentAssetsGreaterThanTotalDebt() 
        external
        whenCurrentAssetsNotZero
        whenTotalDebtNotZero
    {
        currentAssets = 1100 ether;
        totalDebt = multistrategy.strategyTotalDebt(address(strategy));

        (uint256 actualGain, uint256 actualLoss) = strategy.calculateGainAndLoss(currentAssets);
        (uint256 expectedGain, uint256 expectedLoss) = (currentAssets - totalDebt, 0);
        assertEq(actualGain, expectedGain);
        assertEq(actualLoss, expectedLoss);
    }

    function test_CalculateGainAndLoss_CurrentAssetsEqualToTotalDebt() 
        external
        whenCurrentAssetsNotZero
        whenTotalDebtNotZero
    {
        currentAssets = 1000 ether;
        totalDebt = multistrategy.strategyTotalDebt(address(strategy));

        (uint256 actualGain, uint256 actualLoss) = strategy.calculateGainAndLoss(currentAssets);
        (uint256 expectedGain, uint256 expectedLoss) = (0, 0);
        assertEq(actualGain, expectedGain);
        assertEq(actualLoss, expectedLoss);
    }

    function test_CalculateGainAndLoss_CurrentAssetsLowerThanTotalDebt() 
        external
        whenCurrentAssetsNotZero
        whenTotalDebtNotZero
    {
        currentAssets = 900 ether;
        totalDebt = multistrategy.strategyTotalDebt(address(strategy));

        (uint256 actualGain, uint256 actualLoss) = strategy.calculateGainAndLoss(currentAssets);
        (uint256 expectedGain, uint256 expectedLoss) = (0, totalDebt - currentAssets);
        assertEq(actualGain, expectedGain);
        assertEq(actualLoss, expectedLoss);
    }
}