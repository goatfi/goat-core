// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MockERC20 } from "../../../mocks/MockERC20.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract RescueToken_Unit_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotGuardian() external {
        address token = makeAddr("token");
        vm.prank(users.bob);
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        multistrategy.rescueToken(token);
    }

    modifier whenCallerIsGuardian() {
        _;
    }

    function test_RevertWhen_TokenIsAsset() external whenCallerIsGuardian {
        vm.prank(users.guardian);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, address(dai)));
        multistrategy.rescueToken(address(dai));
    }

    modifier whenTokenIsNotAsset() {
        _;
    }

    function test_RescueToken() external whenCallerIsGuardian whenTokenIsNotAsset {
        MockERC20 token = new MockERC20("Token", "TKN");
        token.mint(address(multistrategy), 100 ether);

        uint256 balanceBefore = token.balanceOf(users.guardian);
        
        vm.prank(users.guardian);
        multistrategy.rescueToken(address(token));

        assertEq(token.balanceOf(address(multistrategy)), 0, "rescueToken, contract balance");
        assertEq(token.balanceOf(users.guardian), balanceBefore + 100 ether, "rescueToken, guardian balance");
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RescueToken_OwnerCanCallAsGuardian() external whenCallerIsOwner whenTokenIsNotAsset {
        MockERC20 token = new MockERC20("Token", "TKN");
        token.mint(address(multistrategy), 100 ether);

        uint256 balanceBefore = token.balanceOf(users.owner);
        
        vm.prank(users.owner);
        multistrategy.rescueToken(address(token));

        assertEq(token.balanceOf(address(multistrategy)), 0, "rescueToken by owner, contract balance");
        assertEq(token.balanceOf(users.owner), balanceBefore + 100 ether, "rescueToken by owner, owner balance");
    }
}
