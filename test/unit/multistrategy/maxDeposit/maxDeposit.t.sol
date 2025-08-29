// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";

contract MaxDeposit_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_MaxDeposit_DepositLimitZero() external {
        _userDeposit(users.bob, 1000 ether);

        vm.prank(users.manager); multistrategy.setDepositLimit(0);

        uint256 actualMaxDeposit = multistrategy.maxDeposit(users.bob);
        uint256 expectedMaxDeposit = 0;
        assertEq(actualMaxDeposit, expectedMaxDeposit, "max deposit");
    }

    modifier whenDepositLimitNotZero() {
        vm.prank(users.manager); multistrategy.setDepositLimit(100_000 ether);
        _;
    }

    function test_MaxDeposit_TotalAssetsZero()
        external
        whenDepositLimitNotZero
    {
        uint256 actualMaxDeposit = multistrategy.maxDeposit(users.bob);
        uint256 expectedMaxDeposit = multistrategy.depositLimit();
        assertEq(actualMaxDeposit, expectedMaxDeposit, "max deposit");
    }

    modifier whenTotalAssetsNotZero() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    function test_MaxDeposit()
        external
        whenDepositLimitNotZero
        whenTotalAssetsNotZero
    {
        uint256 actualMaxDeposit = multistrategy.maxDeposit(users.bob);
        uint256 expectedMaxDeposit = multistrategy.depositLimit() - multistrategy.totalAssets();
        assertEq(actualMaxDeposit, expectedMaxDeposit, "max deposit");
    }
}