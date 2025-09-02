// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract CreditAvailable_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;
    uint256 minDebtDelta = 100 ether;
    uint256 maxDebtDelta = 10_000 ether;

    function test_CreditAvailable_ZeroAddress() external view {
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(0));
        uint256 expectedCreditAvailable = 0;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }

    modifier whenNotZeroAddress() {
        strategy = _createAndAddAdapter(5_000, minDebtDelta, maxDebtDelta);
        _;
    }

    function test_CreditAvailable_NoDeposits()
        external
        whenNotZeroAddress
    {
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = 0;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }

    modifier whenThereAreDeposits() {
        _userDeposit(users.bob, 1_000 ether);
        _;
    }

    function test_CreditAvailable_NotActiveStrategy()
        external
        whenNotZeroAddress
        whenThereAreDeposits
    {
        vm.prank(users.manager); multistrategy.retireStrategy(address(strategy));

        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = 0;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }

    modifier whenActiveStrategy() {
        _;
    }

    function test_CreditAvailable_AboveDebtLimit()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
    {
        // Strategy requests a credit. So it will have the same debt as the limit
        vm.prank(users.manager); strategy.requestCredit();
        // We need to reduce the debt ratio of the strategy to lower the limit.
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 2_500);

        // As the strategy has more debt than its limit, there is no credit available
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = 0;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }    
       
    function test_CreditAvailable_DebtEqualAsDebtLimit()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
    {
        // Strategy requests a credit. So it will have the same debt as the limit
        vm.prank(users.manager); strategy.requestCredit();

        // As the strategy has the same debt as its limit, there is no credit available
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = 0;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }

    /// @dev at this point, the strategy did not ask for a credit, so the debt is below the debt limit. 
    modifier whenDebtBelowDebtLimit() {
        _;
    }

    function test_CreditAvailable_CreditBelowMinDebtDelta()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
        whenDebtBelowDebtLimit
    {
        // Strategy requests a credit. So it will have the same debt as the limit
        vm.prank(users.manager); strategy.requestCredit();

        // We increase the debt limit 0.1%, with 1K deposited, this means the strategy can
        // take a credit of 1 extra token.
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 5_010);

        // As 1 token of credit is below the minDebtDelta (100 tokens), assert credit available is 0
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = 0;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }

    modifier whenCreditAboveMinDebtDelta() {
        _;
    }

    function test_CreditAvailable_CreditAboveMaxDebtDelta()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
        whenDebtBelowDebtLimit
        whenCreditAboveMinDebtDelta
    {   
        // Max debt delta is 10K, so we need a big deposit in order to ask for a big credit
        // The strategy hasn't requested any credit yet, so the user deposit is the available credit.
        _userDeposit(users.alice, 20_000 ether);

        // Assert creditAvailable is maxDebtDelta
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = maxDebtDelta;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }

    modifier whenCreditBelowMaxDebtDelta() {
        _;
    }

    function test_CreditAvailable()
        external
        whenNotZeroAddress
        whenThereAreDeposits
        whenActiveStrategy
        whenDebtBelowDebtLimit
        whenCreditAboveMinDebtDelta
        whenCreditBelowMaxDebtDelta
    {
        uint256 actualCreditAvailable = multistrategy.creditAvailable(address(strategy));
        uint256 expectedCreditAvailable = 500 ether;
        assertEq(actualCreditAvailable, expectedCreditAvailable, "creditAvailable");
    }
}