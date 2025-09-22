// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

contract PreviewMint_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    MockStrategyAdapter strategy;
    uint256 amount = 1000 ether;
    uint256 slippage = 100;

    function test_PreviewMint_ZeroShares() external view {
        uint256 actualAssets = multistrategy.previewMint(0);
        uint256 expectedAssets = 0;
        assertEq(actualAssets, expectedAssets, "preview mint");
    }

    modifier whenSharesNotZero() {
        _userDeposit(users.bob, amount);
        _;
    }

    function test_PreviewMint()
        external
        whenSharesNotZero
    {
        uint256 shares = 500 ether;

        uint256 actualAssets = multistrategy.previewMint(shares);
        uint256 expectedAssets = multistrategy.convertToAssets(shares);
        assertEq(actualAssets, expectedAssets, "preview mint");
    }

    modifier whenThereIsActiveStrategy() {
        strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_PreviewMint_MatchesAssets_NoProfit() 
        external 
        whenSharesNotZero 
        whenThereIsActiveStrategy
    {
        uint256 shares = 500 ether;
        deal(multistrategy.asset(), users.bob, shares);

        uint256 previewedShares = multistrategy.previewMint(shares);
        vm.prank(users.bob); dai.approve(address(multistrategy), type(uint256).max);
        vm.prank(users.bob); uint256 actualAssets = multistrategy.mint(shares, users.bob);

        // Check if the previewed shares match the actual shares received
        assertLe(actualAssets, previewedShares, "preview mint should match actual shares when profit is made");
    }

    modifier whenActiveStrategyMadeProfit() {
        strategy.earn(100 ether);
        _;
    }

    function test_PreviewMint_MatchesAssets_WithProfit()
        external 
        whenSharesNotZero 
        whenThereIsActiveStrategy
        whenActiveStrategyMadeProfit

    {
        uint256 shares = 500 ether;
        deal(multistrategy.asset(), users.bob, shares * 2);

        uint256 previewedAssets = multistrategy.previewMint(shares);
        vm.prank(users.bob); dai.approve(address(multistrategy), type(uint256).max);
        vm.prank(users.bob); uint256 actualAssets = multistrategy.mint(shares, users.bob);

        // Check if the previewed shares match the actual shares received
        assertLe(actualAssets, previewedAssets, "preview mint should match actual shares when profit is made");
    }

    modifier whenActiveStrategyMadeLoss() {
        strategy.lose(100 ether);
        _;
    }

    function test_PreviewMint_MatchesAssets_WithLoss()
        external 
        whenSharesNotZero 
        whenThereIsActiveStrategy
        whenActiveStrategyMadeLoss

    {
        uint256 shares = 500 ether;
        deal(multistrategy.asset(), users.bob, shares);

        uint256 previewedShares = multistrategy.previewMint(shares);
        vm.prank(users.bob); dai.approve(address(multistrategy), type(uint256).max);
        vm.prank(users.bob); uint256 actualShares = multistrategy.mint(shares, users.bob);

        // Check if the previewed shares match the actual shares received
        assertLe(actualShares, previewedShares, "preview mint should match actual shares when profit is made");
    }
}