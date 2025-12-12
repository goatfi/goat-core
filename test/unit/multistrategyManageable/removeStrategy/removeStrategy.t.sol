// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockAdapter } from "../../../mocks/MockAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "src/interfaces/IMultistrategyManageable.sol";

contract RemoveStrategy_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockAdapter strategyOne;

    function test_RevertWhen_CallerNotManagerOrOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.removeStrategy(makeAddr("strategy"));
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.removeStrategy(makeAddr("strategy"));
    }

    /// @dev Add a mock strategy to the multistrategy
    modifier whenStrategyIsActive() {
        strategyOne = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_RevertWhen_StrategyDebtRatioNotZero()
        external
        whenCallerIsManager
        whenStrategyIsActive
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyWithActiveDebtRatio.selector));
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));
    }

    modifier whenStrategyWithActiveDebt() {
        _userDeposit(users.bob, 1000 ether);
        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    modifier whenDebtRatioIsZero() {
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategyOne), 0);
        _;
    }

    function test_RevertWhen_StrategyHasOutstandingDebt() 
        external 
        whenCallerIsManager
        whenStrategyIsActive
        whenStrategyWithActiveDebt
        whenDebtRatioIsZero
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyWithActiveDebt.selector));
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));
    }

    modifier whenStrategyHasNoDebt() {
        _;
    }

    function test_RemoveStrategy()
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenDebtRatioIsZero
        whenStrategyHasNoDebt
    {
        // Add two extra strategies to later verify that the order after removal is correct.
        address m2 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        address m3 = address(_createAndAddAdapter(0, 0, type(uint256).max));

        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy)});
        emit IMultistrategyManageable.StrategyRemoved(address(strategyOne));

        // Remove the strategy from withdraw order
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));

        // Assert that the strategy has been deactivated
        assertEq(multistrategy.getStrategyParameters(address(strategyOne)).lastReport, 0, "removeStrategy, last report");
        assertEq(multistrategy.getStrategyParameters(address(strategyOne)).queueIndex, 0, "removeStrategy, queue position");

        // Assert that activeStrategies has been removed from the queue
        assertEq(multistrategy.activeStrategies(), 2, "removeStrategy, activeStrategies");

        // Assert that the strategy has been ordered
        assertEq(multistrategy.getWithdrawOrder()[0], m2, "removeStrategy, withdraw order");
        assertEq(multistrategy.getWithdrawOrder()[1], m3, "removeStrategy, withdraw order");
    }
}