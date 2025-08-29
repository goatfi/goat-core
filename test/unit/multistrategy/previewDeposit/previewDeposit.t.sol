// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

contract PreviewDeposit_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    MockStrategyAdapter strategy;
    uint256 amount = 1000 ether;
    uint256 slippage = 100;

    function test_PreviewDeposit_ZeroAssets() external view {
        uint256 actualShares = multistrategy.previewDeposit(0);
        uint256 expectedShares = 0;
        assertEq(actualShares, expectedShares, "preview deposit");
    }

    modifier whenAssetsNotZero() {
        _userDeposit(users.bob, amount);
        _;
    }

    function test_PreviewDeposit()
        external
        whenAssetsNotZero
    {
        uint256 actualShares = multistrategy.previewDeposit(amount);
        uint256 expectedShares = multistrategy.convertToShares(amount);
        assertEq(actualShares, expectedShares, "preview deposit");
    }

    modifier whenThereIsActiveStrategy() {
        strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_PreviewDeposit_MatchesShares_NoProfit() 
        external 
        whenAssetsNotZero 
        whenThereIsActiveStrategy
    {
        
        uint256 previewedShares = multistrategy.previewDeposit(amount);
        dai.mint(users.bob, amount);
        vm.prank(users.bob); dai.approve(address(multistrategy), amount);
        vm.prank(users.bob); uint256 actualShares = multistrategy.deposit(amount, users.bob);

        assertGe(actualShares, previewedShares, "preview deposit should match actual shares when no profit is made");
    }

    modifier whenActiveStrategyMadeProfit() {
        strategy.earn(100 ether);
        _;
    }

    function test_PreviewDeposit_MatchesShares_WithProfit()
        external 
        whenAssetsNotZero 
        whenThereIsActiveStrategy
        whenActiveStrategyMadeProfit

    {
        vm.prank(users.manager); strategy.sendReport(0);

        uint256 previewedShares = multistrategy.previewDeposit(amount);
        dai.mint(users.bob, amount);
        vm.prank(users.bob); dai.approve(address(multistrategy), amount);
        vm.prank(users.bob); uint256 actualShares = multistrategy.deposit(amount, users.bob);

        // Check if the previewed shares match the actual shares received
        assertGe(actualShares, previewedShares, "preview deposit should match actual shares when profit is made");
    }

    modifier whenActiveStrategyMadeLoss() {
        strategy.lose(100 ether);
        _;
    }

    function test_PreviewDeposit_MatchesShares_WithLoss()
        external 
        whenAssetsNotZero 
        whenThereIsActiveStrategy
        whenActiveStrategyMadeLoss

    {
        vm.prank(users.manager); strategy.sendReport(0);

        uint256 previewedShares = multistrategy.previewDeposit(amount);
        dai.mint(users.bob, amount);
        vm.prank(users.bob); dai.approve(address(multistrategy), amount);
        vm.prank(users.bob); uint256 actualShares = multistrategy.deposit(amount, users.bob);

        // Check if the previewed shares match the actual shares received
        assertGe(actualShares, previewedShares, "preview deposit should match actual shares when loss is made");
    }
}