// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract TotalAssets_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;

    function test_TotalAssets_NoDeposits() external view {
        // Assert that totalAssets are as expected
        uint256 actualTotalAssets = multistrategy.totalAssets();
        uint256 expectedTotalAssets = 0;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    modifier whenThereAreDeposits() {
        _userDeposit(users.bob, 1_000 ether);
        _;
    }

    function test_TotalAssets_NoActiveStrategy() 
        external 
        whenThereAreDeposits
    {
        // Assert that totalAssets are as expected
        uint256 actualTotalAssets = multistrategy.totalAssets();
        uint256 expectedTotalAssets = 1_000 ether;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    modifier whenActiveStrategy() {
        // Add the strategy to the multistrategy
        strategy = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_TotalAssets_NoCreditRequested()
        external
        whenThereAreDeposits
        whenActiveStrategy
    {
        // Assert that totalAssets are as expected
        uint256 actualTotalAssets = multistrategy.totalAssets();
        uint256 expectedTotalAssets = 1_000 ether;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    modifier whenCreditRequested() {
        // Request the credit from the strategy
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_TotalAssets_CreditRequested()
        external
        whenThereAreDeposits
        whenActiveStrategy
        whenCreditRequested
    {
        // Assert that totalAssets are as expected
        uint256 actualTotalAssets = multistrategy.totalAssets();
        uint256 expectedTotalAssets = 1_000 ether;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }

    function test_TotalAssets_MultipleStrategies()
        external
        whenThereAreDeposits
        whenActiveStrategy
        whenCreditRequested
    {
        MockStrategyAdapter strategyTwo = _createAndAddAdapter(5_000, 0, type(uint256).max);
        vm.prank(users.manager); strategyTwo.requestCredit();
        
        // Assert that totalAssets are as expected
        uint256 actualTotalAssets = multistrategy.totalAssets();
        uint256 expectedTotalAssets = 1_000 ether;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets");
    }
}