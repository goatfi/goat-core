// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

contract ReportLoss_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    MockStrategyAdapter strategy;

    function test_RevertWhen_StrategyZeroAddress() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategyLoss.selector));
        multistrategy.reportLoss(address(0), 100 ether);
    }

    modifier whenNotZeroAddress() {
        strategy = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_RevertWhen_NotActiveStrategy()
        external
        whenNotZeroAddress
    {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategyLoss.selector));
        multistrategy.reportLoss(address(strategy), 100 ether);
    }

    modifier whenActiveStrategy() {
        _;
    }

    function test_RevertWhen_ReportedLossHigherThanDebt()
        external
        whenNotZeroAddress
        whenActiveStrategy
    {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategyLoss.selector));
        multistrategy.reportLoss(address(strategy), 100 ether);
    }

    modifier whenLossLowerThanDebt() {
        _userDeposit(users.bob, 1000 ether);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_ReportLoss_ReportZeroLoss() 
        external
        whenNotZeroAddress
        whenActiveStrategy
        whenLossLowerThanDebt
    {
        // Report a zero loss
        multistrategy.reportLoss(address(strategy), 0);

        uint256 actualStrategyTotalLoss = multistrategy.getStrategyParameters(address(strategy)).totalLoss;
        uint256 expectedStrategyTotalLoss = 0;
        assertEq(actualStrategyTotalLoss, expectedStrategyTotalLoss, "reportLoss strat totalLoss");

        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 500 ether;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "reportLoss strate totalDebt");

        uint256 actualMultistrategyTotalDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyTotalDebt = 500 ether;
        assertEq(actualMultistrategyTotalDebt, expectedMultistrategyTotalDebt, "reportLoss multistrategy totalDebt");
    }

    modifier whenLossGreaterThanZero() {
        _;
    }

    function test_ReportLoss()
        external
        whenNotZeroAddress
        whenActiveStrategy
        whenLossLowerThanDebt  
        whenLossGreaterThanZero
    {
        uint256 reportedLoss = 100 ether;

        // Report a zero loss
        multistrategy.reportLoss(address(strategy), reportedLoss);

        uint256 actualStrategyTotalLoss = multistrategy.getStrategyParameters(address(strategy)).totalLoss;
        uint256 expectedStrategyTotalLoss = reportedLoss;
        assertEq(actualStrategyTotalLoss, expectedStrategyTotalLoss, "reportLoss strat totalLoss");

        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 400 ether;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "reportLoss strate totalDebt");

        uint256 actualMultistrategyTotalDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyTotalDebt = 400 ether;
        assertEq(actualMultistrategyTotalDebt, expectedMultistrategyTotalDebt, "reportLoss multistrategy totalDebt");
    }
}