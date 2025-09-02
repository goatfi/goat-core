// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetStrategyMaxDebtDelta_Integration_Concrete_Test is Multistrategy_Base_Test {

    MockStrategyAdapter strategy;
    uint256 maxDebtDelta;

    function test_RevertWhen_CallerNotManager() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotManager.selector, users.bob));
        vm.prank(users.bob); multistrategy.setStrategyMaxDebtDelta(makeAddr("strategy"), maxDebtDelta);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {

        // Expect Revert
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.setStrategyMaxDebtDelta(makeAddr("strategy"), maxDebtDelta);
    }

    /// @dev Add a mock strategy to the multistrategy
    modifier whenStrategyIsActive() {
        strategy = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_RevertWhen_MaxDebtDeltaLowerThanMinDebtDelta()
        external
        whenCallerIsManager
        whenStrategyIsActive
    {
        // Min debt delta is 100 so this is lower
        maxDebtDelta = 10 ether;

        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidDebtDelta.selector));
        vm.prank(users.manager); multistrategy.setStrategyMaxDebtDelta(address(strategy), maxDebtDelta);
    }

    // Ge = greater or equal
    modifier whenMaxDebtDeltaGeMinDebtDelta() {
        // Min debt delta is 100 so this is higher
        maxDebtDelta = 100_000 ether;
        _;
    }

    function test_SetStrategyMaxDebtDelta_NewMaxDebtDelta() 
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenMaxDebtDeltaGeMinDebtDelta
    {
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.StrategyMaxDebtDeltaSet(address(strategy), maxDebtDelta);

        vm.prank(users.manager); multistrategy.setStrategyMaxDebtDelta(address(strategy), maxDebtDelta);

        uint256 actualStrategyMaxDebtDelta = multistrategy.getStrategyParameters(address(strategy)).maxDebtDelta;
        uint256 expectedStrategyMaxDebtDelta = maxDebtDelta;
        assertEq(actualStrategyMaxDebtDelta, expectedStrategyMaxDebtDelta, "setMaxDebtDelta"); 
    }
}