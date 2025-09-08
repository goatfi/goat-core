// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract RetireStrategy_Integration_Concrete_Test is Multistrategy_Base_Test {

    MockStrategyAdapter strategy;

    function test_RevertWhen_CallerNotManager() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.retireStrategy(makeAddr("strategy"));
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {
        // Expect Revert
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.retireStrategy(makeAddr("strategy"));
    }

    /// @dev Add a mock strategy to the multistrategy
    modifier whenStrategyIsActive() {
        strategy = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_RetireStrategy_RetireActiveStrategy()
        external
        whenCallerIsManager
        whenStrategyIsActive 
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy)});
        emit IMultistrategyManageable.StrategyRetired(address(strategy));

        // Retire the strategy
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategy));

        uint256 actualMultistrategyDebtRatio = multistrategy.debtRatio();
        uint256 expectedMultistrategyDebtRatio = 0;
        assertEq(actualMultistrategyDebtRatio, expectedMultistrategyDebtRatio, "retire strategy multistrategy debt ratio");

        uint256 actualStrategyDebtRatio = multistrategy.getStrategyParameters(address(strategy)).debtRatio;
        uint256 expectedStrategyDebtRatio = 0;
        assertEq(actualStrategyDebtRatio, expectedStrategyDebtRatio, "retire strategy strategy debt ratio");
    }

    modifier whenStrategyIsRetired() {
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategy));
        _;
    }

    /// @dev Note that a strategy can be active and retired at the same time.
    ///      Retiring a strategy means we don't want any further deposits into the strategy
    ///      and only withdraws and debt repayments are permitted. So once we retire a strategy
    ///      it is active as it still can hold funds.
    function test_RetireStrategy_RetireAlreadyRetiredStrategy()
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenStrategyIsRetired
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy)});
        emit IMultistrategyManageable.StrategyRetired(address(strategy));

        // Retire the strategy
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategy));

        uint256 actualMultistrategyDebtRatio = multistrategy.debtRatio();
        uint256 expectedMultistrategyDebtRatio = 0;
        assertEq(actualMultistrategyDebtRatio, expectedMultistrategyDebtRatio, "retire strategy multistrategy debt ratio");

        uint256 actualStrategyDebtRatio = multistrategy.getStrategyParameters(address(strategy)).debtRatio;
        uint256 expectedStrategyDebtRatio = 0;
        assertEq(actualStrategyDebtRatio, expectedStrategyDebtRatio, "retire strategy strategy debt ratio");
    }
}