// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";

contract MaxMint_Integration_Concrete_Test is Multistrategy_Base_Test {
    function test_MaxMint_DepositLimitZero() external {
        _userDeposit(users.bob, 1000 ether);

        vm.prank(users.manager); multistrategy.setDepositLimit(0);

        uint256 actualMaxMint = multistrategy.maxMint(users.bob);
        uint256 expectedMaxMint = 0;
        assertEq(actualMaxMint, expectedMaxMint, "max mint");
    }

    modifier whenDepositLimitNotZero() {
        vm.prank(users.manager); multistrategy.setDepositLimit(100_000 ether);
        _;
    }

    function test_MaxMint_TotalAssetsZero()
        external
        whenDepositLimitNotZero
    {
        uint256 actualMaxMint = multistrategy.maxMint(users.bob);
        uint256 expectedMaxMint = multistrategy.convertToShares(multistrategy.depositLimit());
        assertEq(actualMaxMint, expectedMaxMint, "max mint");
    }

    modifier whenTotalAssetsNotZero() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    function test_MaxMint()
        external
        whenDepositLimitNotZero
        whenTotalAssetsNotZero
    {
        uint256 depositLimit = multistrategy.depositLimit();
        uint256 totalAssets = multistrategy.totalAssets();

        uint256 actualMaxMint = multistrategy.maxMint(users.bob);
        uint256 expectedMaxMint = multistrategy.convertToShares(depositLimit - totalAssets);
        assertEq(actualMaxMint, expectedMaxMint, "max mint");
    }
}