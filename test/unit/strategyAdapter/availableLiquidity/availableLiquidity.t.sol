// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";

contract AvailableLiquidity_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_AvailableLiquidity() public {
        uint256 amount = 1_000 ether;
        _requestCredit(amount);

        uint256 actualAvailableLiquidity = strategy.availableLiquidity();
        assertEq(actualAvailableLiquidity, amount);
    }
}