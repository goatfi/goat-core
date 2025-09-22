// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

contract MaxWithdraw_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategyOne;

    function test_MaxWithdraw_ZeroAddress() external view {
        uint256 actualMaxWithdraw = multistrategy.maxWithdraw(address(0));
        uint256 expectedMaxWithdraw = 0;
        assertEq(actualMaxWithdraw, expectedMaxWithdraw, "max withdraw for zero address");
    }

    modifier whenAddressNotZero() {
        _;
    }

    function test_MaxWithdraw_NoShares() external view whenAddressNotZero {
        uint256 actualMaxWithdraw = multistrategy.maxWithdraw(users.bob);
        uint256 expectedMaxWithdraw = 0;
        assertEq(actualMaxWithdraw, expectedMaxWithdraw, "max withdraw when no shares");
    }

    modifier whenHoldsShares() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    function test_MaxWithdraw_WithShares()
        external
        whenAddressNotZero
        whenHoldsShares
    {
        uint256 shares = multistrategy.balanceOf(users.bob);
        uint256 expectedMaxWithdraw = Math.min(multistrategy.convertToAssets(shares), multistrategy.availableLiquidity());

        uint256 actualMaxWithdraw = multistrategy.maxWithdraw(users.bob);
        assertEq(actualMaxWithdraw, expectedMaxWithdraw, "max withdraw with shares");
    }

    function test_MaxWithdraw_WithShares_SufficientLiquidity()
        external
        whenAddressNotZero
        whenHoldsShares
    {
        uint256 shares = multistrategy.balanceOf(users.bob);
        uint256 assetsFromShares = multistrategy.convertToAssets(shares);
        uint256 availableLiquidity = multistrategy.availableLiquidity();
        assertGe(availableLiquidity, assetsFromShares, "sufficient liquidity");

        uint256 actualMaxWithdraw = multistrategy.maxWithdraw(users.bob);
        assertEq(actualMaxWithdraw, assetsFromShares, "max withdraw should be assets from shares");
    }

    function test_MaxWithdraw_WithShares_InsufficientLiquidity()
        external
        whenAddressNotZero
        whenHoldsShares
    {
        // Set up strategy
        strategyOne = _createAndAddAdapter(5_000, 0, 100_000 ether);
        vm.prank(users.manager); strategyOne.requestCredit();

        // Reduce liquidity by borrowing
        strategyOne.vault().borrow(500 ether);

        uint256 shares = multistrategy.balanceOf(users.bob);
        uint256 assetsFromShares = multistrategy.convertToAssets(shares);
        uint256 availableLiquidity = multistrategy.availableLiquidity();
        assertLt(availableLiquidity, assetsFromShares, "insufficient liquidity");

        uint256 actualMaxWithdraw = multistrategy.maxWithdraw(users.bob);
        assertEq(actualMaxWithdraw, availableLiquidity, "max withdraw should be available liquidity");
    }
}