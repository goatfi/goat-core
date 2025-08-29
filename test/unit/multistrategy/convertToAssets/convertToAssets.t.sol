// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";

contract ConvertToAssets_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 amount = 1000 ether;

    function test_ConvertToAssets_ZeroTotalSupply() external view {
        // Assert share value is zero when totalSupply is 0
        uint256 actualAssets = multistrategy.convertToAssets(amount);
        uint256 expectedAssets = amount;
        assertEq(actualAssets, expectedAssets, "convertToAssets");
    }

    modifier whenTotalSupplyNotZero() {
        _userDeposit(users.bob, amount);
        _;
    }

    function test_ConvertToAssets_ZeroSharesAmount() 
        external
        whenTotalSupplyNotZero
    {
        uint256 actualAssets = multistrategy.convertToAssets(0);
        uint256 expectedAssets = 0;
        assertEq(actualAssets, expectedAssets, "convertToAssets");
    }

    modifier whenSharesAmountNotZero() {
        _;
    }

    function test_ConvertToAssets()
        external
        whenTotalSupplyNotZero
        whenSharesAmountNotZero
    {
        uint256 totalAssets = multistrategy.totalAssets();
        uint256 totalSupply = multistrategy.totalSupply();

        // Assert share value is the amount of shares multiplied by freeFunds, divided by totalSupply
        uint256 actualAssets = multistrategy.convertToAssets(amount);
        uint256 expectedAssets = Math.mulDiv(amount, totalAssets + 1, totalSupply + 1, Math.Rounding.Floor);
        assertEq(actualAssets, expectedAssets, "convertToAssets");
    }
}