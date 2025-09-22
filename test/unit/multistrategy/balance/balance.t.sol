// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract Balance_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    uint256 depositAmount = 1000 ether;

    function test_Balance_NoCredit() external {
        _userDeposit(users.bob, depositAmount);

        uint256 actualBalance = multistrategy.balance();
        uint256 expectedBalance = depositAmount;
        assertEq(actualBalance, expectedBalance, "balance");
    }

    modifier whenActiveCredit() {
        _userDeposit(users.bob, depositAmount);
        MockStrategyAdapter adapter = _createAndAddAdapter(6_000, 0, 100_000 ether);
        vm.prank(users.manager); adapter.requestCredit();
        _;
    }

    function test_Balance_ActiveCredit()
        external
        whenActiveCredit
    {
        uint256 actualBalance = multistrategy.balance();
        uint256 expectedBalance = depositAmount - 600 ether;
        assertEq(actualBalance, expectedBalance, "balance");
    }
}