// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

contract PreviewRedeem_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    MockStrategyAdapter strategy;
    uint256 amount = 1000 ether;
    uint256 slippage = 1000;

    function test_PreviewRedeem_ZeroShares() external view {
        uint256 actualAssets = multistrategy.previewRedeem(0);
        uint256 expectedAssets = 0;
        assertEq(actualAssets, expectedAssets, "preview redeem");
    }

    modifier whenSharesNotZero() {
        _userDeposit(users.bob, amount);
        _;
    }

    function test_PreviewRedeem_EnoughLiquidity()
        external
        whenSharesNotZero
    {
        uint256 actualAssets = multistrategy.previewRedeem(amount);
        uint256 expectedAssets = multistrategy.convertToAssets(amount);
        assertEq(actualAssets, expectedAssets, "preview redeem");
    }

    modifier whenNotEnoughLiquidity() {
        strategy = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_PreviewRedeem_SlippageLimitZero()
        external
        whenSharesNotZero
        whenNotEnoughLiquidity
    {
        uint256 actualAssets = multistrategy.previewRedeem(amount);
        uint256 expectedAssets = multistrategy.convertToAssets(amount);
        assertEq(actualAssets, expectedAssets, "preview redeem");
    }

    modifier whenSlippageLimitNotZero() {
        _;
    }

    function test_PreivewRedeem_MaxBps()
        external
        whenSharesNotZero
        whenNotEnoughLiquidity
        whenSlippageLimitNotZero
    {
        vm.prank(users.manager); multistrategy.setSlippageLimit(10_000);
        uint256 actualAssets = multistrategy.previewRedeem(amount);
        uint256 expectedAssets = 0;
        assertEq(actualAssets, expectedAssets, "preview redeem");
    }

    modifier whenSlippageLimitNotMaxBps() {
        vm.prank(users.manager); multistrategy.setSlippageLimit(slippage);
        _;
    }

    function test_PreviewRedeem_SlippageLimitNotZero()
        external
        whenSharesNotZero
        whenNotEnoughLiquidity
        whenSlippageLimitNotZero
        whenSlippageLimitNotMaxBps
    {
        uint256 actualAssets = multistrategy.previewRedeem(amount);
        uint256 expectedAssets = multistrategy.convertToAssets(amount.mulDiv(10_000 - slippage, 10_000));
        assertEq(actualAssets, expectedAssets, "preview redeem");
    }
}