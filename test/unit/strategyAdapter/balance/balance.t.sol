// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";

contract Balance_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_Balance() public {
        uint256 amount = 1 ether;
        deal(address(dai), address(strategy), amount);

        uint256 actualBalance = strategy.balance();
        assertEq(actualBalance, amount);
    }
}