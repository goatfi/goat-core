// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract StrategyTotalDebt_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;

    function test_StrategyTotalDebt_ZeroAddress() external view {
        // Assert that zero address has 0 debt
        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(0));
        uint256 expectedStrategyTotalDebt = 0;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "strategyTotalDebt");
    }

    modifier whenNotZeroAddress() {
        strategy = _createAndAddAdapter(5_000, 100 ether, type(uint256).max);
        _;
    }

    function test_StrategyTotalDebt_NoActiveStrategy() external whenNotZeroAddress {
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategy));

        // Assert that a not active strategy has 0 debt
        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 0;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "strategyTotalDebt");
    }

    modifier whenActiveStrategy() {
        _;
    }

    function test_StrategyTotalDebt_NoCreditRequested() 
        external 
        whenNotZeroAddress
        whenActiveStrategy
    {
        // Assert debt is 0 as the strategy hasn't requested any credit
        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 0;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "strategyTotalDebt");
    }

    modifier whenCreditRequested() {
        // We need some funds into the multistrategy, else no credit can be requested
        _userDeposit(users.bob, 1_000 ether);
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    function test_StrategyTotalDebt_CreditRequested() 
        external
        whenNotZeroAddress
        whenActiveStrategy
        whenCreditRequested
    {
        // Debt should be half the user deposit, as strategy's debtRatio is 50%
        uint256 creditRequested = 500 ether;

        // Assert the strategy total debt is the same as the credit requested
        uint256 actualStrategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = creditRequested;
        assertEq(actualStrategyTotalDebt, expectedStrategyTotalDebt, "strategyTotalDebt");
    }
}