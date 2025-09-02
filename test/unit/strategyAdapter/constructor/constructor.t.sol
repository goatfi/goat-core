
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { MockERC20 } from "../../../mocks/MockERC20.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

contract Constructor_Unit_Test is StrategyAdapter_Base_Test {

    function test_RevertWhen_AssetDoesNotMatch() external {
        MockERC20 wrongAsset = new MockERC20("Wrong Token", "WRONG");

        vm.expectRevert(abi.encodeWithSelector(Errors.AssetMismatch.selector, address(dai), address(wrongAsset)));
        new MockStrategyAdapter(address(multistrategy), address(wrongAsset));
    }

    modifier whenAssetMatches() {
        _;
    }

    function test_Constructor_Success() external whenAssetMatches {
        assertEq(strategy.owner(), users.manager, "owner");
        assertFalse(strategy.paused(), "paused");
        assertFalse(strategy.guardians(makeAddr("guardian")), "guardians");
        assertEq(strategy.multistrategy(), address(multistrategy), "multistrategy");
        assertEq(strategy.asset(), address(dai), "asset");
        assertEq(strategy.slippageLimit(), 0, "slippageLimit");
        assertEq(strategy.name(), "Mock", "name");
        assertEq(strategy.id(), "MOCK", "id");
        assertEq(IERC20(dai).allowance(address(strategy), address(multistrategy)), type(uint256).max, "approval");
    }
}