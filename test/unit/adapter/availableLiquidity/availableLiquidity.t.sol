// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";

contract AvailableLiquidity_Integration_Concrete_Test is Adapter_Base_Test {
    function test_AvailableLiquidity() public {
        uint256 amount = 1_000 ether;
        _requestCredit(amount);

        uint256 actualAvailableLiquidity = strategy.availableLiquidity();
        assertEq(actualAvailableLiquidity, amount);
    }
}