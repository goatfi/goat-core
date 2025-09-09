// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MStrat } from "src/libraries/DataTypes.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract RemoveStrategy_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategyOne;
    MockStrategyAdapter strategyTwo;
    uint8 decimals;

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
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy)});
        emit IMultistrategyManageable.StrategyRemoved(address(strategyOne));

        // Remove the strategy from withdraw order
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));

        MStrat.StrategyParams memory strategyParams = multistrategy.getStrategyParameters(address(strategyOne));

        // Assert that the strategy has been deactivated
        uint256 actualActivation = strategyParams.activation;
        uint256 expectedActivation = 0;
        assertEq(actualActivation, expectedActivation, "removeStrategy activation");

        // Assert that activeStrategies has been reduced.
        uint256 actualActiveStrategies = multistrategy.activeStrategies();
        uint256 expectedActiveStrategies = 0;
        assertEq(actualActiveStrategies, expectedActiveStrategies, "removeStrategy activeStrategies");

        // Assert that the strategy has been ordered
        address actualAddressAtWithdrawOrderPos0 = multistrategy.getWithdrawOrder()[0];
        address expectedAddressAtWithdrawOrderPos0 = address(0);
        assertEq(actualAddressAtWithdrawOrderPos0, expectedAddressAtWithdrawOrderPos0, "removeStrategy withdraw order");
    }
}