
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { MockAdapter } from "../../../mocks/MockAdapter.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

contract Constructor_Unit_Test is Adapter_Base_Test {
    MockAdapter adapter;

    function test_RevertWhen_MultistrategyDoesNOTImplementERC4626() public {
        vm.expectRevert();
        adapter = new MockAdapter(makeAddr("dummy"));
    }

    function test_Constructor_Success() external view {
        assertEq(strategy.owner(), users.manager, "owner");
        assertEq(strategy.multistrategy(), address(multistrategy), "multistrategy");
        assertEq(strategy.asset(), address(dai), "asset");
        assertEq(strategy.slippageLimit(), 0, "slippageLimit");
        assertEq(strategy.name(), "Mock", "name");
        assertEq(strategy.id(), "MOCK", "id");
        assertEq(IERC20(dai).allowance(address(strategy), address(multistrategy)), type(uint256).max, "approval");
    }
}