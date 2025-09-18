// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Withdraw_Integration_Concrete_Test is Multistrategy_Base_Test {
    using Math for uint256;

    uint256 deposit = 1000 ether;
    uint256 amountToWithdraw;

    MockStrategyAdapter strategyOne;
    MockStrategyAdapter strategyTwo;

    function test_RevertWhen_ContractIsPaused() external {
        vm.prank(users.guardian); multistrategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        multistrategy.requestCredit();
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_RevertWhen_NotEnoughSharesToCoverWithdraw() 
        external 
        whenContractNotPaused
    {
        amountToWithdraw = 1000 ether;

        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxWithdraw.selector, users.bob, amountToWithdraw, 0));
        multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    modifier whenEnoughSharesToCoverWithdraw() {
        _userDeposit(users.bob, deposit);
        _;
    }

    function test_RevertWhen_NotEnoughLiquidity() 
        external 
        whenContractNotPaused
        whenEnoughSharesToCoverWithdraw
    {
        strategyOne = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategyOne.requestCredit();
        strategyOne.vault().borrow(100 ether);

        amountToWithdraw = 1000 ether;

        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxWithdraw.selector, users.bob, amountToWithdraw, 900 ether));
        multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    modifier whenEnoughLiquidity() {
        strategyOne = _createAndAddAdapter(10_000, 0, type(uint256).max);
        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    function test_RevertWhen_SlippageNotRespected() 
        external 
        whenContractNotPaused
        whenEnoughSharesToCoverWithdraw
        whenEnoughLiquidity
    {
        strategyOne.lose(100 ether);
        amountToWithdraw = 100 ether;

        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 1_000, 0));
        multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    modifier whenSlippageRespected() {
        _;
    }

    function test_Withdraw_WithSlippage() 
        external 
        whenContractNotPaused
        whenEnoughSharesToCoverWithdraw
        whenEnoughLiquidity
        whenSlippageRespected
    {
        strategyOne.lose(100 ether);
        amountToWithdraw = 100 ether;

        vm.prank(users.manager); strategyOne.setSlippageLimit(1_000);
        vm.prank(users.manager); multistrategy.setSlippageLimit(1_000);

        // Multistrategy [previewRedeem] will always round to its favor. So it will round assets to ceil.
        uint256 sharesWithSlippage = amountToWithdraw.mulDiv(10 ether, 9 ether, Math.Rounding.Ceil);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.bob, users.bob, users.bob, amountToWithdraw, sharesWithSlippage);

        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    modifier whenNoSlippage() {
        _;
    }

    function test_Withdraw() external whenContractNotPaused whenEnoughSharesToCoverWithdraw whenEnoughLiquidity whenNoSlippage {
        amountToWithdraw = deposit;

        uint256 sharesBefore = multistrategy.balanceOf(users.bob);
        uint256 assetsBefore = dai.balanceOf(users.bob);

        vm.expectEmit(address(multistrategy));
        emit IERC4626.Withdraw(users.bob, users.bob, users.bob, amountToWithdraw, amountToWithdraw);

        vm.prank(users.bob); uint256 sharesBurned = multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);

        assertEq(sharesBurned, sharesBefore);
        assertEq(multistrategy.balanceOf(users.bob), sharesBefore - sharesBurned);
        assertEq(dai.balanceOf(users.bob), assetsBefore + amountToWithdraw);
    }
}