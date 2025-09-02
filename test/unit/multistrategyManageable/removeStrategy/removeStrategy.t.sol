// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract RemoveStrategy_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategyOne;
    MockStrategyAdapter strategyTwo;
    uint8 decimals;

    function test_RevertWhen_CallerNotManager() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotManager.selector, users.bob));
        vm.prank(users.bob); multistrategy.removeStrategy(makeAddr("strategy"));
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {
        // Expect Revert
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
        // Expect a revert when trying to remove the strategy from the withdraw order
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotRetired.selector));
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));
    }

    modifier whenStrategyDebtGreaterThanZero() {
        _userDeposit(users.bob, 1000 ether);
        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    modifier whenDebtRatioIsZero() {
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategyOne));
        _;
    }

    function test_RevertWhen_StrategyHasOutstandingDebt() 
        external 
        whenCallerIsManager
        whenStrategyIsActive
        whenStrategyDebtGreaterThanZero
        whenDebtRatioIsZero
    {
        // Expect a revert when trying to remove the strategy from the withdraw order
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyWithOutstandingDebt.selector));
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));
    }

    modifier whenStrategyHasNoDebt() {
        _;
    }

    function test_RevertWhen_StrategyIsNotInWithdrawOrder() 
        external 
        whenCallerIsManager
        whenStrategyIsActive
        whenDebtRatioIsZero
        whenStrategyHasNoDebt
    {
        // Expect Revert
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.removeStrategy(makeAddr("strategy"));
    }

    modifier whenStrategyIsInWithdrawOrder() {
        _;
    }

    function test_RemoveStrategy_RemoveStrategyFromWithdrawOrder()
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenDebtRatioIsZero
        whenStrategyHasNoDebt
        whenStrategyIsInWithdrawOrder
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy)});
        emit IMultistrategyManageable.StrategyRemoved(address(strategyOne));

        // Remove the strategy from withdraw order
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyOne));
    
        bool isInWithdrawOrder;
        bool expectedInWithdrawOrder = false;

        // Check if the strategy is in the withdraw order array
        address[] memory actualWithdrawOrder = multistrategy.getWithdrawOrder();
        for(uint256 i = 0; i < actualWithdrawOrder.length; ++i) {
            if(actualWithdrawOrder[i] == address(strategyOne)) {
                isInWithdrawOrder = true;
            }
        }
        
        // Assert it has been removed
        assertEq(isInWithdrawOrder, expectedInWithdrawOrder, "removeStrategy");

        address actualAddressAtWithdrawOrderPos0 = multistrategy.getWithdrawOrder()[0];
        address expectedAddressAtWithdrawOrderPos0 = address(0);
        // Assert that the strategy has been ordered
        assertEq(actualAddressAtWithdrawOrderPos0, expectedAddressAtWithdrawOrderPos0, "removeStrategy withdraw order");
    }

    /// @dev Add a mock strategy to the multistrategy
    modifier whenTwoActiveStrategies() {
        strategyTwo = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategyTwo));
        _;
    }

    function test_RemoveStrategy_RemoveStrategyNotFirstInQueue()
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenTwoActiveStrategies
        whenDebtRatioIsZero
        whenStrategyHasNoDebt
        whenStrategyIsInWithdrawOrder
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy)});
        emit IMultistrategyManageable.StrategyRemoved(address(strategyTwo));

        // Remove the strategy from withdraw order
        vm.prank(users.manager); multistrategy.removeStrategy(address(strategyTwo));
    
        bool isInWithdrawOrder;
        bool expectedInWithdrawOrder = false;

        // Check if the strategy is in the withdraw order array
        address[] memory actualWithdrawOrder = multistrategy.getWithdrawOrder();
        for(uint256 i = 0; i < actualWithdrawOrder.length; ++i) {
            if(actualWithdrawOrder[i] == address(strategyTwo)) {
                isInWithdrawOrder = true;
            }
        }
        
        // Assert it has been removed
        assertEq(isInWithdrawOrder, expectedInWithdrawOrder, "removeStrategy");

        address actualAddressAtWithdrawOrderPos0 = multistrategy.getWithdrawOrder()[1];
        address expectedAddressAtWithdrawOrderPos0 = address(0);
        // Assert that the strategy has been ordered
        assertEq(actualAddressAtWithdrawOrderPos0, expectedAddressAtWithdrawOrderPos0, "removeStrategy withdraw order");
    }
}