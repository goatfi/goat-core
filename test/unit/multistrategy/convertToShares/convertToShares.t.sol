// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";

contract ConvertToShares_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 depositAmount = 1000 ether;

    function test_ConvertToShares_ZeroAmount() external view {
        //Assert that shares for assets is zero when the assets of shares is zero
        uint256 actualShares = multistrategy.convertToShares(0);
        uint256 expectedShares = 0;
        assertEq(actualShares, expectedShares, "convertToShares");
    }

    modifier whenAssetsNotZero() {
        _;
    }

    function test_ConvertToShares_ZeroTotalSupply() 
        external view
        whenAssetsNotZero
    {
        //Assert that shares for assets is zero when the assets of shares is zero
        uint256 actualShares = multistrategy.convertToShares(depositAmount);
        uint256 expectedShares = depositAmount;
        assertEq(actualShares, expectedShares, "convertToShares");
    }

    modifier whenTotalSupplyNotZero() {
        _userDeposit(users.bob, depositAmount);
        _;
    }

    function test_ConvertToShares()
        external
        whenAssetsNotZero
        whenTotalSupplyNotZero
    {   
        uint256 decimalsOffset = uint256(18) - assetDecimals;
        uint256 freeFunds = multistrategy.totalAssets();
        uint256 totalSupply = multistrategy.totalSupply();

        //Assert that shares is the assets multiplied by totalSupply and divided by freeFunds
        uint256 actualShares = multistrategy.convertToShares(depositAmount);
        uint256 expectedShares = Math.mulDiv(depositAmount, totalSupply + 10 ** decimalsOffset, freeFunds + 1, Math.Rounding.Floor);
        assertEq(actualShares, expectedShares, "convertToShares");
    }
}