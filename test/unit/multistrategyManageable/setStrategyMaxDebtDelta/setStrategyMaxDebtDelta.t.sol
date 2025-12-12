// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockAdapter } from "../../../mocks/MockAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "src/interfaces/IMultistrategyManageable.sol";

contract SetStrategyMaxDebtDelta_Integration_Concrete_Test is Multistrategy_Base_Test {

    MockAdapter strategy;
    uint256 minDebtDelta = 100 ether;
    uint256 maxDebtDelta;

    function test_RevertWhen_CallerNotManager() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.setStrategyMaxDebtDelta(makeAddr("strategy"), maxDebtDelta);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.setStrategyMaxDebtDelta(makeAddr("strategy"), maxDebtDelta);
    }

    modifier whenStrategyIsActive() {
        strategy = _createAndAddAdapter(5_000, minDebtDelta, type(uint256).max);
        _;
    }

    function test_RevertWhen_MaxDebtDeltaLowerThanMinDebtDelta()
        external
        whenCallerIsManager
        whenStrategyIsActive
    {
        // Min debt delta is 100 so this is lower
        maxDebtDelta = 10 ether;

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