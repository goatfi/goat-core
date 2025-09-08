// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetStrategyMinDebtDelta_Integration_Concrete_Test is Multistrategy_Base_Test {

    MockStrategyAdapter strategy;
    uint256 minDebtDelta;

    function test_RevertWhen_CallerNotManager() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.setStrategyMinDebtDelta(makeAddr("strategy"), minDebtDelta);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {
        // Expect Revert
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.setStrategyMinDebtDelta(makeAddr("strategy"), minDebtDelta);
    }

    /// @dev Add a mock strategy to the multistrategy
    modifier whenStrategyIsActive() {
        strategy = _createAndAddAdapter(5_000, 100 ether, 100_000 ether);
        _;
    }

    function test_RevertWhen_MinDebtDeltaHigherThanMaxDebtDelta()
        external
        whenCallerIsManager
        whenStrategyIsActive
    {
        // Max debt delta is 100K so this is higher
        minDebtDelta = 200_000 ether;

        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidDebtDelta.selector));
        vm.prank(users.manager); multistrategy.setStrategyMinDebtDelta(address(strategy), minDebtDelta);
    }

    // Le = lower or equal
    modifier whenMinDebtDeltaLeMaxDebtDelta() {
        // Max debt delta is 100K so this is lower
        minDebtDelta = 100 ether;
        _;
    }

    function test_SetStrategyMinDebtDelta_NewMinDebtDelta() 
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenMinDebtDeltaLeMaxDebtDelta
    {
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.StrategyMinDebtDeltaSet(address(strategy), minDebtDelta);

        vm.prank(users.manager); multistrategy.setStrategyMinDebtDelta(address(strategy), minDebtDelta);

        uint256 actualStrategyMinDebtDelta = multistrategy.getStrategyParameters(address(strategy)).minDebtDelta;
        uint256 expectedStrategyMinDebtDelta = minDebtDelta;
        assertEq(actualStrategyMinDebtDelta, expectedStrategyMinDebtDelta, "setMinDebtDelta"); 
    }
}