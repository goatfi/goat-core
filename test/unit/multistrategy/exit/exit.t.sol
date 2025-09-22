// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";

contract Exit_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    uint256 depositAmount = 1_000 ether;
    uint256 withdrawAmount = 1_000 ether;
    address receiver;
    address owner;

    MockStrategyAdapter strategyOne;
    MockStrategyAdapter strategyTwo;

    function setUp() public override {
        super.setUp();
        _userDeposit(users.bob, depositAmount);
        owner = users.bob;
    }

    function test_RevertWhen_ReceiverIsZeroAddress() external {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, receiver));
        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);
    }

    modifier whenReceiverNotZeroAddress() {
        receiver = users.alice;
        _;
    }

    function test_RevertWhen_ReceiverIsMultistrategyAddress()
        external
        whenReceiverNotZeroAddress
    {
        receiver = address(multistrategy);
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, receiver));
        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);
    }

    modifier whenReceiverNotMultistrategy() {
        receiver = users.alice;
        _;
    }

    function test_RevertWhen_AmountOfSharesIsZero()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
    {
        uint256 shares = 0;

        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAmount.selector, shares));
        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);
    }

    modifier whenSharesNotZero() {
        _;
    }

    modifier whenCallerNotOwner() {
        _;
    }

    function test_RevertWhen_CallerNotOwner_InsufficientAllowance()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
    {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientAllowance(address,uint256,uint256)")), users.alice, 0, shares));
        multistrategy.exit(users.alice, receiver, owner, withdrawAmount, shares);
    }

    modifier whenEnoughAllowance() {
        vm.prank(owner); multistrategy.approve(users.alice, withdrawAmount);
        _;
    }

    modifier whenMultistrategyBalanceHigherOrEqualToAssets() {
        // No strategies added, so balance is depositAmount
        _;
    }

    function test_Exit_CallerNotOwner_NoWithdrawProcess()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
        whenEnoughAllowance
        whenMultistrategyBalanceHigherOrEqualToAssets
    {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.alice, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(users.alice, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
        assertEq(dai.balanceOf(address(multistrategy)), 0, "Assets deducted from multistrategy");
    }

    modifier whenMultistrategyBalanceLowerThanAssets() {
        strategyOne = _createAndAddAdapter(5000, 0, type(uint256).max);
        strategyTwo = _createAndAddAdapter(5000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        vm.prank(users.manager); strategyTwo.requestCredit();
        _;
    }

    modifier whenNotEnoughLiquidity() {
        // Reduce liquidity in adapters
        strategyOne.vault().borrow(100 ether);
        strategyTwo.vault().borrow(100 ether);
        _;
    }

    function test_RevertWhen_CallerNotOwner_NotEnoughLiquidity()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
        whenEnoughAllowance
        whenMultistrategyBalanceLowerThanAssets
        whenNotEnoughLiquidity
    {
        // Try to redeem all, but not enough liquidity
        uint256 shares = multistrategy.balanceOf(owner);
        uint256 assets = multistrategy.previewRedeem(shares);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")), address(multistrategy),  multistrategy.previewRedeem(shares) - 200 ether, multistrategy.previewRedeem(shares)));
        multistrategy.exit(users.alice, receiver, owner, assets, shares);
    }

    modifier whenEnoughLiquidity() {
        _;
    }

    function test_Exit_CallerNotOwner_WithWithdrawProcess()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
        whenEnoughAllowance
        whenMultistrategyBalanceLowerThanAssets
        whenEnoughLiquidity
    {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.alice, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(users.alice, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
        assertEq(dai.balanceOf(address(multistrategy)), 0, "Assets adjusted");
    }

    // Now for when caller is the owner
    modifier whenCallerIsTheOwner() {
        _;
    }

    function test_Exit_CallerIsOwner_NoWithdrawProcess()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerIsTheOwner
        whenMultistrategyBalanceHigherOrEqualToAssets
    {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(owner, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
        assertEq(dai.balanceOf(address(multistrategy)), 0, "Assets deducted from multistrategy");
    }

    function test_RevertWhen_CallerIsOwner_NotEnoughLiquidity()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerIsTheOwner
        whenMultistrategyBalanceLowerThanAssets
        whenNotEnoughLiquidity
    {
        // Try to redeem all, but not enough liquidity
        uint256 shares = multistrategy.balanceOf(owner);
        uint256 assets = multistrategy.previewRedeem(shares);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")), address(multistrategy),  multistrategy.previewRedeem(shares) - 200 ether, multistrategy.previewRedeem(shares)));
        multistrategy.exit(owner, receiver, owner, assets, shares);
    }

    function test_Exit_CallerIsOwner_WithWithdrawProcess()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerIsTheOwner
        whenMultistrategyBalanceLowerThanAssets
        whenEnoughLiquidity
    {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(owner, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
        assertEq(dai.balanceOf(address(multistrategy)), 0, "Assets deducted from multistrategy");
    }
}