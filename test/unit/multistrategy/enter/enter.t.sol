// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";

contract Enter_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    uint256 assets = 100 ether;
    
    function test_RevertWhen_ReceiverIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, address(0)));
        multistrategy.enter(users.alice, address(0), 100 ether, 100 ether);
    }

    modifier whenReceiverNotZeroAddress() {
        _;
    }

    function test_RevertWhen_ReceiverIsContractAddress()
        external
        whenReceiverNotZeroAddress
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, address(multistrategy)));
        multistrategy.enter(users.alice, address(multistrategy), 100 ether, 100 ether);
    }

    modifier whenReceiverNotContractAddress() {
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotContractAddress
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAmount.selector, 0));
        multistrategy.enter(users.alice, users.alice, 0, 100 ether);
    }

    modifier whenAmountIsGreaterThanZero() {
        _;
    }

    function test_RevertWhen_CallerNotEnoughBalance()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotContractAddress
    {
        uint256 shares = multistrategy.convertToShares(assets);
        vm.prank(users.bob); dai.approve(address(multistrategy), assets);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")), users.bob, 0, assets));
        multistrategy.enter(users.bob, users.alice, assets, shares);
    }

    modifier whenCallerHasEnoughBalance {
        dai.mint(users.bob, assets);
        vm.prank(users.bob); dai.approve(address(multistrategy), assets);
        _;
    }

    function test_Enter()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotContractAddress
        whenAmountIsGreaterThanZero
        whenCallerHasEnoughBalance
    {
        uint256 shares = multistrategy.convertToShares(assets);

        uint256 initialCallerBalance = dai.balanceOf(users.bob);
        uint256 initialMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 initialReceiverShares = multistrategy.balanceOf(users.alice);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Deposit(users.bob, users.alice, assets, shares);

        multistrategy.enter(users.bob, users.alice, assets, shares);

        // Assert assets transferred
        assertEq(dai.balanceOf(users.bob), initialCallerBalance - assets, "enter, caller balance");
        assertEq(dai.balanceOf(address(multistrategy)), initialMultistrategyBalance + assets, "enter, multistrategy balance");

        // Assert shares minted
        assertEq(multistrategy.balanceOf(users.alice), initialReceiverShares + shares, "enter, shares");
    }
}