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

    modifier whenStrategyHasNoAssetsToWithdraw() {
        // Create a strategy with no debt (so assetsToWithdraw will be 0)
        strategyOne = _createAndAddAdapter(5000, 0, type(uint256).max);
        strategyTwo = _createAndAddAdapter(5000, 0, type(uint256).max);
        // Don't request credit for strategyOne, so it has no debt
        vm.prank(users.manager); strategyTwo.requestCredit();
        _;
    }

    function test_Exit_CallerNotOwner_WithdrawProcess_WithTotalDebtSkip()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
        whenEnoughAllowance
        whenStrategyHasNoAssetsToWithdraw
    {
        // StrategyOne has no debt, so assetsToWithdraw = 0, should continue to strategyTwo
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.alice, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(users.alice, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
    }

    function test_Exit_CallerNotOwner_WithdrawProcess_WithLiquiditySkip()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
        whenEnoughAllowance
        whenStrategyWithdrawsInsufficient
    {
        // StrategyOne will withdraw partial amount, strategyTwo should complete the withdrawal
        // 400 ether where borrowed, so we can withraw up to the max withdarwable amount.
        withdrawAmount = multistrategy.maxWithdraw(owner);
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.alice, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(users.alice, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
    }

    function test_Exit_CallerNotOwner_Withdraw()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerNotOwner
        whenEnoughAllowance
        whenStrategyWithdrawsSufficient
    {
        // StrategyOne should have enough liquidity to complete the withdrawal
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.alice, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(users.alice, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
    }

    function test_Exit_CallerIsOwner_WithdrawProcess_WithTotalDebtSkip()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerIsTheOwner
        whenStrategyHasNoAssetsToWithdraw
    {
        // StrategyOne has no debt, so assetsToWithdraw = 0, should continue to strategyTwo
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(owner, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
    }

    modifier whenStrategyWithdrawsInsufficient() {
        strategyOne = _createAndAddAdapter(5000, 0, type(uint256).max);
        strategyTwo = _createAndAddAdapter(5000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        vm.prank(users.manager); strategyTwo.requestCredit();

        // Reduce liquidity in strategyOne so it has insufficient for its share
        // Each strategy gets 500 ether, so borrow 400 ether leaving only 100 ether
        strategyOne.vault().borrow(400 ether);
        _;
    }

    function test_Exit_CallerIsOwner_WithdrawProcess_WithLiquiditySkip()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerIsTheOwner
        whenStrategyWithdrawsInsufficient
    {
        // StrategyOne will withdraw partial amount, strategyTwo should complete the withdrawal
        // 400 ether where borrowed, so we can withraw up to the max withdarwable amount.
        withdrawAmount = multistrategy.maxWithdraw(owner);
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(owner, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
    }

    modifier whenStrategyWithdrawsSufficient() {
        strategyOne = _createAndAddAdapter(5000, 0, type(uint256).max);
        strategyTwo = _createAndAddAdapter(5000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        vm.prank(users.manager); strategyTwo.requestCredit();
        _;
    }

    function test_Exit_CallerIsOwner_Withdraw()
        external
        whenReceiverNotZeroAddress
        whenReceiverNotMultistrategy
        whenSharesNotZero
        whenCallerIsTheOwner
        whenStrategyWithdrawsSufficient
    {
        uint256 shares = multistrategy.previewWithdraw(withdrawAmount);
        uint256 ownerSharesBefore = multistrategy.balanceOf(owner);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(owner, receiver, owner, withdrawAmount, shares);

        multistrategy.exit(owner, receiver, owner, withdrawAmount, shares);

        assertEq(multistrategy.balanceOf(owner), ownerSharesBefore - shares, "Shares burned");
        assertEq(dai.balanceOf(receiver), withdrawAmount, "Assets transferred to receiver");
    }
}