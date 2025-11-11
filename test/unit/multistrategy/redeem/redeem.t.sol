// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Redeem_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    uint256 deposit = 1000 ether;
    uint256 sharesToRedeem;

    MockStrategyAdapter strategyOne;
    MockStrategyAdapter strategyTwo;

    function test_RevertWhen_ContractIsPaused() external {
        // Pause the multistrategy
        vm.prank(users.guardian); multistrategy.pause();

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        multistrategy.requestCredit();
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_RevertWhen_CallerNotEnoughSharesToCoverRedeem() external {
        sharesToRedeem = 1000 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxRedeem.selector, users.bob, sharesToRedeem, 0));
        multistrategy.redeem(sharesToRedeem, users.bob, users.bob);
    }

    modifier whenHasCallerEnoughSharesToCoverRedeem() {
        _userDeposit(users.bob, deposit);
        _;
    }

    modifier whenEnoughSharesToCoverRedeem() {
        _userDeposit(users.bob, deposit);
        _;
    }

    function test_RevertWhen_NotEnoughLiquidity()
        external
        whenContractNotPaused
        whenEnoughSharesToCoverRedeem
    {
        strategyOne = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategyOne.requestCredit();
        strategyOne.vault().borrow(100 ether);

        sharesToRedeem = 1000 ether;

        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxRedeem.selector, users.bob, sharesToRedeem, 900 ether));
        multistrategy.redeem(sharesToRedeem, users.bob, users.bob);
    }

    modifier whenEnoughLiquidity() {
        strategyOne = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    function test_RevertWhen_SlippageNotRespected()
        external
        whenContractNotPaused
        whenEnoughSharesToCoverRedeem
        whenEnoughLiquidity
    {
        strategyOne.lose(100 ether);
        sharesToRedeem = 100 ether;

        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 1_000, 0));
        multistrategy.redeem(sharesToRedeem, users.bob, users.bob);
    }

    modifier whenSlippageRespected() {
        _;
    }

    function test_Redeem_WithSlippage()
        external
        whenContractNotPaused
        whenEnoughSharesToCoverRedeem
        whenEnoughLiquidity
        whenSlippageRespected
    {
        strategyOne.lose(100 ether);
        sharesToRedeem = 100 ether;

        vm.prank(users.manager); strategyOne.setSlippageLimit(1_000);
        vm.prank(users.manager); multistrategy.setSlippageLimit(1_000);

        // Multistrategy [previewRedeem] will always round to its favor. So it will round assets to floor.
        uint256 assetsWithSlippage = sharesToRedeem.mulDiv(9 ether, 10 ether, Math.Rounding.Floor);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.bob, users.bob, users.bob, assetsWithSlippage, sharesToRedeem);

        vm.prank(users.bob); multistrategy.redeem(sharesToRedeem, users.bob, users.bob);
    }

    modifier whenNoSlippage() {
        _;
    }

    function test_Redeem() 
        external 
        whenContractNotPaused 
        whenEnoughSharesToCoverRedeem 
        whenEnoughLiquidity 
        whenNoSlippage 
    {
        sharesToRedeem = deposit;

        uint256 sharesBefore = multistrategy.balanceOf(users.bob);
        uint256 assetsBefore = dai.balanceOf(users.bob);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.bob, users.bob, users.bob, sharesToRedeem, sharesToRedeem);

        vm.prank(users.bob); uint256 assetsReceived = multistrategy.redeem(sharesToRedeem, users.bob, users.bob);

        assertEq(assetsReceived, deposit);
        assertEq(multistrategy.balanceOf(users.bob), sharesBefore - sharesToRedeem);
        assertEq(dai.balanceOf(users.bob), assetsBefore + assetsReceived);
    }
}