// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";

contract Deposit_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 assets;
    address recipient;

    function test_RevertWhen_ContractIsPaused() external {
        recipient = users.bob;

        vm.prank(users.guardian); multistrategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        multistrategy.deposit(assets, recipient);
    }

    modifier whenContractNotPaused() {
        _;
    }

    /// @dev Deposit limit is 100K tokens
    function test_RevertWhen_AssetsAboveMaxDeposit()
        external
        whenContractNotPaused
    {
        assets = 200_000 ether;

        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxDeposit.selector, recipient, assets, 100_000 ether));
        multistrategy.deposit(assets, recipient);
    }

    modifier whenDepositLimitRespected() {
        assets = 1000 ether;
        _;
    }

    modifier whenCallerHasEnoughBalance() {
        dai.mint(users.bob, assets);
        vm.prank(users.bob); dai.approve(address(multistrategy), assets);
        _;
    }

    function test_Deposit()
        external
        whenContractNotPaused
        whenDepositLimitRespected
        whenCallerHasEnoughBalance
    {
        recipient = users.bob;
        uint256 shares = multistrategy.previewDeposit(assets);

        vm.expectEmit({emitter: address(multistrategy)});
        emit IERC4626.Deposit(users.bob, recipient, assets, shares);

        vm.prank(users.bob); multistrategy.deposit(assets, recipient);

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
        uint256 expectedMultistrategyBalance = assets;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "deposit multistrategy balance");
    }
}