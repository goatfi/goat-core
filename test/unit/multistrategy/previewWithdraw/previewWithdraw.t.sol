// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

contract PreviewWithdraw_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    MockStrategyAdapter strategy;
    uint256 amount = 1000 ether;
    uint256 slippage = 100;

    function test_PreviewWithdraw_ZeroAssets() external view {
        uint256 actualShares = multistrategy.previewWithdraw(0);
        uint256 expectedShares = 0;
        assertEq(actualShares, expectedShares, "preview withdraw");
    }

    modifier whenAssetsNotZero() {
        _userDeposit(users.bob, amount);
        _;
    }

    function test_PreviewWithdraw_EnoughLiquidity()
        external
        whenAssetsNotZero
    {
        uint256 actualShares = multistrategy.previewWithdraw(amount);
        uint256 expectedShares = multistrategy.convertToShares(amount);
        assertEq(actualShares, expectedShares, "preview withdraw");
    }

    modifier whenNotEnoughLiquidity() {
        strategy = _createAndAddAdapter(6_000, 0, type(uint256).max);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_PreviewWithdraw_SlippageLimitZero()
        external
        whenAssetsNotZero
        whenNotEnoughLiquidity
    {
        uint256 actualShares = multistrategy.previewWithdraw(amount);
        uint256 expectedShares = multistrategy.convertToShares(amount);
        assertEq(actualShares, expectedShares, "preview withdraw");
    }

    modifier whenSlippageLimitNotZero() {
        vm.prank(users.manager); multistrategy.setSlippageLimit(10_000);
        _;
    }

    function test_PreviewWithdraw_SlippageMAXBPS()
        external
        whenAssetsNotZero
        whenNotEnoughLiquidity
        whenSlippageLimitNotZero
    {
        uint256 actualShares = multistrategy.previewWithdraw(amount);
        uint256 expectedShares = type(uint256).max;
        assertEq(actualShares, expectedShares, "preview withdraw");
    }

    modifier whenSlippageLimitNotMaxBps() {
        vm.prank(users.manager); multistrategy.setSlippageLimit(slippage);
        _;
    }

    function test_PreviewWithdraw_SlippageLimitNotZero()
        external
        whenAssetsNotZero
        whenNotEnoughLiquidity
        whenSlippageLimitNotZero
        whenSlippageLimitNotMaxBps
    {
        uint256 shares = multistrategy.convertToShares(amount);

        uint256 actualShares = multistrategy.previewWithdraw(amount);
        uint256 expectedShares = shares.mulDiv(10_000, 10_000 - slippage, Math.Rounding.Ceil);
        assertEq(actualShares, expectedShares, "preview withdraw");
    }
}