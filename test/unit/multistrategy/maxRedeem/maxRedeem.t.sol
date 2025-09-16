// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";

contract MaxRedeem_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategyOne;

    function test_MaxRedeem_ZeroAddress() external view {
        uint256 actualMaxRedeem = multistrategy.maxRedeem(address(0));
        uint256 expectedMaxRedeem = 0;
        assertEq(actualMaxRedeem, expectedMaxRedeem, "max redeem for zero address");
    }

    modifier whenAddressNotZero() {
        _;
    }

    function test_MaxRedeem_NoShares() external view whenAddressNotZero {
        uint256 actualMaxRedeem = multistrategy.maxRedeem(users.bob);
        uint256 expectedMaxRedeem = 0;
        assertEq(actualMaxRedeem, expectedMaxRedeem, "max redeem when no shares");
    }

    modifier whenAddressHoldsShares() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    function test_MaxRedeem_WithShares()
        external
        whenAddressNotZero
        whenAddressHoldsShares
    {
        uint256 balanceShares = multistrategy.balanceOf(users.bob);
        uint256 availableLiquidity = multistrategy.availableLiquidity();
        uint256 maxSharesFromLiquidity = multistrategy.convertToShares(availableLiquidity);
        uint256 expectedMaxRedeem = Math.min(balanceShares, maxSharesFromLiquidity);
        uint256 actualMaxRedeem = multistrategy.maxRedeem(users.bob);
        assertEq(actualMaxRedeem, expectedMaxRedeem, "max redeem with shares");
    }

    function test_MaxRedeem_WithShares_SufficientLiquidity()
        external
        whenAddressNotZero
        whenAddressHoldsShares
    {
        strategyOne = _createAndAddAdapter(5_000, 0, 100_000 ether);
        vm.prank(users.manager); strategyOne.requestCredit();

        uint256 balanceShares = multistrategy.balanceOf(users.bob);
        uint256 actualMaxRedeem = multistrategy.maxRedeem(users.bob);
        assertEq(actualMaxRedeem, balanceShares, "max redeem sufficient liquidity");
    }

    function test_MaxRedeem_WithShares_InsufficientLiquidity()
        external
        whenAddressNotZero
        whenAddressHoldsShares
    {
        strategyOne = _createAndAddAdapter(10_000, 0, 100_000 ether);
        vm.prank(users.manager); strategyOne.requestCredit();
        strategyOne.vault().borrow(800 ether);

        uint256 availableLiquidity = multistrategy.availableLiquidity();
        uint256 maxSharesFromLiquidity = multistrategy.convertToShares(availableLiquidity);
        uint256 balanceShares = multistrategy.balanceOf(users.bob);
        assertLt(maxSharesFromLiquidity, balanceShares, "liquidity insufficient");

        uint256 actualMaxRedeem = multistrategy.maxRedeem(users.bob);
        assertEq(actualMaxRedeem, maxSharesFromLiquidity, "max redeem insufficient liquidity");
    }
}