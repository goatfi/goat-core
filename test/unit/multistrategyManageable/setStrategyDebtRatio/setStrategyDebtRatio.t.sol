// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockAdapter } from "../../../mocks/MockAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "src/interfaces/IMultistrategyManageable.sol";

contract SetStrategyDebtRatio_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockAdapter strategy;
    uint256 debtRatio;

    function test_RevertWhen_CallerNotManager() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.setStrategyDebtRatio(makeAddr("strategy"), debtRatio);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_StrategyIsNotActive() external whenCallerIsManager {
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, makeAddr("strategy")));
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(makeAddr("strategy"), debtRatio);
    }

    /// @dev Add a mock strategy to the multistrategy
    modifier whenStrategyIsActive() {
        strategy = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_RevertWhen_DebtRatioAboveMaximum()
        external
        whenCallerIsManager
        whenStrategyIsActive
    {   
        // Debt ratio will be 110%, that is above the maximum (100%)
        debtRatio = 11_000;

        vm.expectRevert(abi.encodeWithSelector(Errors.DebtRatioAboveMaximum.selector, debtRatio));
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), debtRatio);
    }

    modifier whenDebtRatioBelowMaximum() {
        debtRatio = 6_000;
        _;
    }

    function test_SetStrategyDebtRatio_SetNewDebtRatio()
        external
        whenCallerIsManager
        whenStrategyIsActive
        whenDebtRatioBelowMaximum
    {   
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.StrategyDebtRatioSet(address(strategy), debtRatio);

        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), debtRatio);

        // Assert the strategy debt ratio has been set
        uint256 actualStrategyDebtRatio = multistrategy.getStrategyParameters(address(strategy)).debtRatio;
        uint256 expectedStrategyDebtRatio = debtRatio;
        assertEq(actualStrategyDebtRatio, expectedStrategyDebtRatio, "setStrategyDebtRatio strategy debt ratio");

        // Assert the multistrategy debt ratio has been set
        uint256 actualMultistrategyDebtRatio = multistrategy.debtRatio();
        uint256 expectedMultistrategyDebtRatio = debtRatio;
        assertEq(actualMultistrategyDebtRatio, expectedMultistrategyDebtRatio, "setStrategyDebtRatio multistrategy debt ratio");
    }
}