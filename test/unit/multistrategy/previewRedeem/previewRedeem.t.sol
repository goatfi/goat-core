// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Constants } from "../../../../src/libraries/Constants.sol";

contract PreviewRedeem_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    uint256 depositAmount = 1000 ether;
    uint256 redeemShares = 500 ether;

    function test_PreviewRedeem_ZeroShares() external view {
        uint256 actualAssets = multistrategy.previewRedeem(0);
        uint256 expectedAssets = 0;
        assertEq(actualAssets, expectedAssets, "previewRedeem: zero shares should return zero assets");
    }

    modifier whenSharesNotZero() {
        _;
    }

    function test_PreviewRedeem_ZeroTotalSupply() 
        external view
        whenSharesNotZero
    {
        
        uint256 actualAssets = multistrategy.previewRedeem(redeemShares);
        uint256 expectedAssets = multistrategy.convertToAssets(redeemShares);
        assertEq(actualAssets, expectedAssets, "previewRedeem: zero totalSupply");
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

    function test_PreviewRedeem_NoSlippage()
        external
        whenSharesNotZero
        whenTotalSupplyNotZero
        whenSlippageLimitZero
    {
        uint256 actualAssets = multistrategy.previewRedeem(redeemShares);
        uint256 expectedAssets = multistrategy.convertToAssets(redeemShares);
        assertEq(actualAssets, expectedAssets, "previewRedeem: no slippage should return exact conversion");
    }

    modifier whenSlippageLimitNotZero() {
        vm.prank(users.manager);
        multistrategy.setSlippageLimit(100); // 1% slippage
        _;
    }

    function test_PreviewRedeem_WithSlippage()
        external
        whenSharesNotZero
        whenTotalSupplyNotZero
        whenSlippageLimitNotZero
    {
        uint256 slippageLimit = multistrategy.slippageLimit();
        
        uint256 actualAssets = multistrategy.previewRedeem(redeemShares);
        uint256 expectedAssets = multistrategy.convertToAssets(redeemShares).mulDiv(Constants.MAX_BPS - slippageLimit, Constants.MAX_BPS, Math.Rounding.Floor);
        
        assertEq(actualAssets, expectedAssets, "previewRedeem: with slippage should return decreased assets");
    }
}