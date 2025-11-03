// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Multistrategy } from "../../../../src/Multistrategy.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

contract PreviewWithdraw_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;
    
    uint256 depositAmount = 1000 ether;
    uint256 withdrawAmount = 500 ether;

    function test_PreviewWithdraw_ZeroAssets() external view {
        // Assert that shares for zero assets returns zero
        uint256 actualShares = multistrategy.previewWithdraw(0);
        uint256 expectedShares = 0;
        assertEq(actualShares, expectedShares, "previewWithdraw: zero assets should return zero shares");
    }

    modifier whenAssetsNotZero() {
        _;
    }

    function test_PreviewWithdraw_ZeroTotalSupply() 
        external view
        whenAssetsNotZero
    {
        uint256 actualShares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 expectedShares = multistrategy.convertToShares(withdrawAmount);
        assertEq(actualShares, expectedShares, "previewWithdraw: zero totalSupply");
    }

    modifier whenTotalSupplyNotZero() {
        _userDeposit(users.bob, depositAmount);
        _;
    }

    modifier whenSlippageLimitZero() {
        vm.prank(users.manager);
        multistrategy.setSlippageLimit(0);
        _;
    }

    function test_PreviewWithdraw_NoSlippage()
        external
        whenAssetsNotZero
        whenTotalSupplyNotZero
        whenSlippageLimitZero
    {
        uint256 actualShares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 expectedShares = multistrategy.convertToShares(withdrawAmount);
        assertEq(actualShares, expectedShares, "previewWithdraw: no slippage");
    }

    modifier whenSlippageLimitNotZero() {
        vm.prank(users.manager);
        multistrategy.setSlippageLimit(100); // 1% slippage
        _;
    }

    function test_PreviewWithdraw_WithSlippage()
        external
        whenAssetsNotZero
        whenTotalSupplyNotZero
        whenSlippageLimitNotZero
    {
        uint256 slippageLimit = multistrategy.slippageLimit();
        
        uint256 actualShares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 expectedShares = multistrategy.convertToShares(withdrawAmount).mulDiv(Constants.MAX_BPS, Constants.MAX_BPS - slippageLimit, Math.Rounding.Ceil);
        
        assertEq(actualShares, expectedShares, "previewWithdraw: with slippage should return increased shares");
    }
}