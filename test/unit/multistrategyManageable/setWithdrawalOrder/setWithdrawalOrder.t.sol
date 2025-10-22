// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetWithdrawOrder_Integration_Concrete_Test is Multistrategy_Base_Test {
    address[] strategies;
    address m1;
    address m2;
    address m3;

    function addMockStrategy() internal returns (address mockStrategy) {
        mockStrategy = address(_createAndAddAdapter(0, 0, type(uint256).max));
    }

    function test_RevertWhen_CallerNotManager() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.setWithdrawOrder(strategies);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_LengthDoNotMatch() external whenCallerIsManager {
        strategies = new address[](2);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawOrder.selector));
        vm.prank(users.manager);multistrategy.setWithdrawOrder(strategies);
    }

    modifier whenLengthMatches() {
        _;
    }

    function test_RevertWhen_OrderHasZeroAddress()
        external
        whenCallerIsManager
    {
        //Create two strategies
        m1 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        m2 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        
        strategies = [address(0), m2];

        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawOrder.selector));
        vm.prank(users.manager); multistrategy.setWithdrawOrder(strategies);
    }

    function test_RevertWhen_InactiveStrategy()
        external
        whenCallerIsManager
        whenLengthMatches
    {
        // Create two strategies. Only the first one will be added.
        m1 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        m2 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        m3 = address(_createAdapter());

        strategies = [m1, m3];

        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawOrder.selector));
        vm.prank(users.manager); multistrategy.setWithdrawOrder(strategies);
    }

    modifier whenAllStrategiesAreActive() {
        _;
    }

    function test_RevertWhen_DuplicateStrategies()
        external
        whenCallerIsManager
        whenLengthMatches
        whenAllStrategiesAreActive
    {   
        // Add two strategies to the multistrategy so they are present in the withdrawOrder
        m1 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        m2 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        
        // Create an array with duplicate strategies
        strategies = [m1, m1];

        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawOrder.selector));
        vm.prank(users.manager); multistrategy.setWithdrawOrder(strategies);
    }

    modifier whenNoDuplicates() {
        _;
    }

    function test_SetWithdrawOrder_NewWithdrawOrder()
        external
        whenCallerIsManager
        whenLengthMatches
        whenAllStrategiesAreActive
        whenNoDuplicates
    {
        // Add two strategies to the multistrategy so they are present in the withdrawOrder
        m1 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        m2 = address(_createAndAddAdapter(0, 0, type(uint256).max));
        
        // Create a new withdraw order
        strategies = [m2, m1];

        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.WithdrawOrderSet();

        vm.prank(users.manager); multistrategy.setWithdrawOrder(strategies);

        address[] memory withdrawOrder = multistrategy.getWithdrawOrder();

        // Assert the withdraw order has been set correctly
        assertEq(withdrawOrder[0], m2, "setWithdrawOrder, order in array");
        assertEq(withdrawOrder[1], m1, "setWithdrawOrder, order in array");

        // Assert the queue position in the params has been correctly set
        assertEq(multistrategy.getStrategyParameters(m2).queueIndex, 0, "setWithdrawOrder, queue position");
        assertEq(multistrategy.getStrategyParameters(m1).queueIndex, 1, "setWithdrawOrder, queue position");
    }
}