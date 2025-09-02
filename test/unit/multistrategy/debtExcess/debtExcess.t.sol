// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract DebtExcess_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;
    uint256 minDebtDelta = 100 ether;
    uint256 maxDebtDelta = 10_000 ether;

    function test_DebtExcess_ZeroAddress() external view {
        uint256 actualDebtExcess = multistrategy.debtExcess(address(strategy));
        uint256 expectedDebtExcess = 0;
        assertEq(actualDebtExcess, expectedDebtExcess, "debtExcess");
    }

    modifier whenNotZeroAddress() {
        strategy = _createAndAddAdapter(5_000, minDebtDelta, maxDebtDelta);
        _;
    }

    function test_DebtExcess_NoDeposits()
        external
        whenNotZeroAddress
    {
        uint256 actualDebtExcess = multistrategy.debtExcess(address(strategy));
        uint256 expectedDebtExcess = 0;
        assertEq(actualDebtExcess, expectedDebtExcess, "debtExcess");
    }

    modifier whenThereAreDeposits() {
        _userDeposit(users.bob, 1_000 ether);
        _;
    }

    function test_DebtExcess_NotActiveStrategy()
        external
        whenNotZeroAddress
        whenThereAreDeposits
    {
        uint256 actualDebtExcess = multistrategy.debtExcess(address(strategy));
        uint256 expectedDebtExcess = 0;
        assertEq(actualDebtExcess, expectedDebtExcess, "debtExcess");
    }

    modifier whenActiveStrategy() {
        _;
    }

    function test_DebtExcess_ZeroDebtRatio() 
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
    {
        // Strategy requests a credit. So it will have debt
        vm.prank(users.manager); strategy.requestCredit();

        // Set the strategy debt ratio to 0, so all debt is excess debt
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);

        uint256 actualDebtExcess = multistrategy.debtExcess(address(strategy));
        uint256 expectedDebtExcess = multistrategy.strategyTotalDebt(address(strategy));
        assertEq(actualDebtExcess, expectedDebtExcess, "debtExcess");
    }

    modifier whenNotZeroDebtRatio() {
        _;
    }

    function test_DebtExcess_DebtBelowDebtLimit()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
        whenNotZeroDebtRatio
    {
        // Strategy requests a credit. So it will have debt
        vm.prank(users.manager);strategy.requestCredit();

        // Set the strategy debt ratio to 60%, so strategy's debt is below the debt limit
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 6_000);

        uint256 actualDebtExcess = multistrategy.debtExcess(address(strategy));
        uint256 expectedDebtExcess = 0;
        assertEq(actualDebtExcess, expectedDebtExcess, "debtExcess");
    }

    modifier whenDebtAboveDebtLimit() {
        _;
    }

    function test_DebtExcess_DebtAboveDebtLimit()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
        whenNotZeroDebtRatio
        whenDebtAboveDebtLimit
    {
        // Strategy requests a credit. So it will have debt
        vm.prank(users.manager); strategy.requestCredit();

        // Set the strategy debt ratio to 40%, so strategy's debt is above the debt limit
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 4_000);

        uint256 actualDebtExcess = multistrategy.debtExcess(address(strategy));
        uint256 expectedDebtExcess = 100 ether;
        assertEq(actualDebtExcess, expectedDebtExcess, "debtExcess");
    }
}