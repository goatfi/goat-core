// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";

contract Deposit_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 amount;
    address recipient;

    function test_RevertWhen_ContractIsPaused() external {
        recipient = users.bob;

        // Pause the multistrategy
        vm.prank(users.guardian); multistrategy.pause();

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        multistrategy.deposit(amount, recipient);
    }

    modifier whenContractNotPaused() {
        _;
    }

    modifier whenNotRetired() {
        _;
    }

    /// @dev Deposit limit is 100K tokens
    function test_RevertWhen_AssetsAboveMaxDeposit()
        external
        whenContractNotPaused
        whenNotRetired
    {
        amount = 200_000 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxDeposit.selector, recipient, amount, 100_000 ether));
        multistrategy.deposit(amount, recipient);
    }

    modifier whenDepositLimitRespected() {
        amount = 1000 ether;
        _;
    }

    function test_RevertWhen_RecipientIsZeroAddress() 
        external
        whenContractNotPaused
        whenNotRetired
        whenDepositLimitRespected 
    {
        recipient = address(0);

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidAddress.selector, address(0)));
        multistrategy.deposit(amount, recipient);
    }

    modifier whenRecipientNotZeroAddress() {
        recipient = users.bob;
        _;
    }

    function test_RevertWhen_RecipientIsContractAddress()
        external
        whenContractNotPaused
        whenNotRetired
        whenDepositLimitRespected 
        whenRecipientNotZeroAddress
    {
        recipient = address(multistrategy);

        // Expect a revert
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InvalidAddress.selector,
                address(multistrategy)
            )
        );
        multistrategy.deposit(amount, recipient);
    }

    modifier whenRecipientNotContractAddress() {
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenContractNotPaused
        whenNotRetired
        whenDepositLimitRespected
        whenRecipientNotZeroAddress
        whenRecipientNotContractAddress
    {
        amount = 0;
        recipient = users.bob;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAmount.selector, 0));
        multistrategy.deposit(amount, recipient);
    }

    modifier whenAmountIsGreaterThanZero {
        _;
    }

    function test_RevertWhen_CallerHasInsufficientBalance()
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
        whenDepositLimitRespected
        whenRecipientNotContractAddress
        whenAmountIsGreaterThanZero
    {
        recipient = users.bob;

        // Expect a revert
        vm.expectRevert();
        multistrategy.deposit(amount, recipient);
    }

    modifier whenCallerHasEnoughBalance() {
        dai.mint(users.bob, amount);
        vm.prank(users.bob); dai.approve(address(multistrategy), amount);
        _;
    }

    function test_Deposit()
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
        whenDepositLimitRespected
        whenRecipientNotContractAddress
        whenAmountIsGreaterThanZero
        whenCallerHasEnoughBalance
    {
        recipient = users.bob;
        uint256 shares = multistrategy.previewDeposit(amount);

        vm.expectEmit({emitter: address(multistrategy)});
        emit IERC4626.Deposit(users.bob, recipient, amount, shares);

        vm.prank(users.bob); multistrategy.deposit(amount, recipient);

        // Assert correct amount of shares have been minted to recipient
        uint256 actualMintedShares = multistrategy.balanceOf(recipient);
        uint256 expectedMintedShares = shares;
        assertEq(actualMintedShares, expectedMintedShares, "deposit");

        // Assert the assets have been deducted from the caller
        uint256 actualUserBalance = dai.balanceOf(recipient);
        uint256 expectedUserBalance = 0;
        assertEq(actualUserBalance, expectedUserBalance, "deposit user balance");

        // Assert the assets have been transferred to the multistrategy
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = amount;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "deposit multistrategy balance");
    }
}