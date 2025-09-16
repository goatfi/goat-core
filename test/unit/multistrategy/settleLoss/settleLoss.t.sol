// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

contract SettleLoss_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    MockStrategyAdapter strategy;

    modifier whenNotZeroAddress() {
        strategy = _createAdapter();
        _;
    }

    function test_RevertWhen_NotActiveStrategy()
        external
        whenNotZeroAddress
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategyLoss.selector));
        multistrategy.settleLoss(address(strategy), 1);
    }

    modifier whenActiveStrategy() {
        strategy = _createAndAddAdapter(5_000, 0, type(uint256).max);
        _;
    }

    function test_RevertWhen_SettledLossHigherThanDebt()
        external
        whenNotZeroAddress
        whenActiveStrategy
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategyLoss.selector));
        multistrategy.settleLoss(address(strategy), 1);
    }

    modifier whenActiveDebt() {
        _userDeposit(users.bob, 1000 ether);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_RevertWhen_SettleZeroLoss() 
        external
        whenNotZeroAddress
        whenActiveStrategy
        whenActiveDebt
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategyLoss.selector));
        multistrategy.settleLoss(address(strategy), 0);
    }

    modifier whenLossGreaterThanZero() {
        _;
    }

    function test_SettleLoss()
        external
        whenNotZeroAddress
        whenActiveStrategy
        whenActiveDebt  
        whenLossGreaterThanZero
    {
        uint256 settledLoss = 100 ether;

        multistrategy.settleLoss(address(strategy), settledLoss);

        uint256 actualStrategyTotalLoss = multistrategy.getStrategyParameters(address(strategy)).totalLoss;
        uint256 expectedStrategyTotalLoss = settledLoss;
        assertEq(actualStrategyTotalLoss, expectedStrategyTotalLoss, "settleLoss strat totalLoss");

        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 400 ether;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "settleLoss strate totalDebt");

        uint256 actualMultistrategyTotalDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyTotalDebt = 400 ether;
        assertEq(actualMultistrategyTotalDebt, expectedMultistrategyTotalDebt, "settleLoss multistrategy totalDebt");
    }
}