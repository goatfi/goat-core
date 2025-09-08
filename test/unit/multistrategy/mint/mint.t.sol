// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";

contract Mint_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 shares;
    address recipient;

    function test_RevertWhen_ContractIsPaused() external {
        vm.prank(users.guardian); multistrategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        multistrategy.mint(shares, recipient);
    }

    modifier whenContractNotPaused() {
        _;
    }

    modifier whenNotRetired() {
        _;
    }

    function test_RevertWhen_RecipientIsZeroAddress() 
        external
        whenContractNotPaused
        whenNotRetired
    {
        shares = 1000 ether;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidAddress.selector, address(0))
        );
        multistrategy.mint(shares, recipient);
    }

    modifier whenRecipientNotZeroAddress() {
        recipient = users.bob;
        _;
    }

    function test_RevertWhen_RecipientIsContractAddress() 
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
    {
        shares = 1000 ether;
        recipient = address(multistrategy);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidAddress.selector, address(multistrategy))
        );
        multistrategy.mint(shares, recipient);
    }

    modifier whenRecipientNotContractAddress() {
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
        whenRecipientNotContractAddress
    {
        shares = 0;

        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAmount.selector, 0));
        multistrategy.mint(shares, recipient);
    }

    modifier whenAmountIsGreaterThanZero() {
        shares = 1000 ether;
        _;
    }

    /// @dev Deposit limit is 100K tokens
    function test_RevertWhen_AssetsAboveMaxMint()
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
        whenRecipientNotContractAddress
        whenAmountIsGreaterThanZero
    {
        shares = 150_000 ether;
        recipient = users.bob;

        vm.expectRevert(abi.encodeWithSelector(Errors.ERC4626ExceededMaxMint.selector, recipient, shares, 100_000 ether));
        multistrategy.mint(shares, recipient);
    }

    /// @dev Approve the tokens to be able to deposit
    modifier whenDepositLimitRespected() {
        vm.prank(users.bob); dai.approve(address(multistrategy), shares);
        _;
    }

    function test_RevertWhen_CallerHasInsufficientBalance()
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
        whenRecipientNotContractAddress
        whenAmountIsGreaterThanZero
        whenDepositLimitRespected
    {
        vm.expectRevert();
        vm.prank(users.bob); multistrategy.mint(shares, recipient);
    }

    modifier whenCallerHasEnoughBalance() {
        dai.mint(users.bob, 1000 ether);
        _;
    }

    function test_Mint()
        external
        whenContractNotPaused
        whenNotRetired
        whenRecipientNotZeroAddress
        whenRecipientNotContractAddress
        whenAmountIsGreaterThanZero
        whenDepositLimitRespected
        whenCallerHasEnoughBalance
    {
        uint256 assets = multistrategy.previewMint(shares);

        vm.expectEmit({emitter: address(multistrategy)});
        emit IERC4626.Deposit(users.bob, recipient, assets, shares);
        
        vm.prank(users.bob);multistrategy.mint(shares, recipient);

        // Assert correct amount of shares have been minted to recipient
        uint256 actualShares = multistrategy.balanceOf(recipient);
        uint256 expectedShares = shares;
        assertEq(actualShares, expectedShares, "mint");

        // Assert the assets have been deducted from the caller
        uint256 actualUserBalance = dai.balanceOf(recipient);
        uint256 expectedUserBalance = 0;
        assertEq(actualUserBalance, expectedUserBalance, "mint user balance");

        // Assert the assets have been transferred to the multistrategy
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = assets;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "mint multistrategy balance");
    }
}