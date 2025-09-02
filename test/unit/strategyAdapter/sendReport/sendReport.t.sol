// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract SendReport_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.requestCredit();
    }

    modifier whenCallerOwner() {
        _;
    }

    function test_RevertWhen_ContractPaused() 
        external
        whenCallerOwner
    {
        vm.prank(users.guardian); strategy.pause();
        
        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.manager); strategy.sendReport(0);
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_RevertWhen_RepayAmountHigherThanTotalAssets()
        external
        whenCallerOwner
        whenContractNotPaused
    {
        // Request a credit from the multistrategy
        _requestCredit(1_000 ether);

        // Make a loss
        strategy.lose(100 ether);

        // Set the strategy debt ratio to 0, se we can repay the debt
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);

        uint256 repayAmount = 1000 ether;

        // Expect a revert when the strategy manager wants to repay all the debt but it doesn't have the assets to do so
        vm.expectRevert();
        vm.prank(users.manager); strategy.sendReport(repayAmount);
    }

    function test_RevertWhen_SlippageLimitNotRespected()
        external
        whenCallerOwner
        whenContractNotPaused
    {
        // Set the slippage limit of the strategy to 10%
        vm.prank(users.manager); strategy.setSlippageLimit(1_000);

        // Set the staking slippage to be 15%
        vm.prank(users.manager); strategy.setStakingSlippage(1_500);

        // Request a credit from the multistrategy
        _requestCredit(1_000 ether);

        // Set the strategy debt ratio to 0, se we can repay the debt
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 900 ether, 850 ether));
        vm.prank(users.manager); strategy.sendReport(1_000 ether);
    }

    modifier whenSlippageLimitRespected() {
        // Set the slippage limit of the strategy to 0%
        vm.prank(users.manager); strategy.setSlippageLimit(0);
        // Set the staking slippage to be 0%
        vm.prank(users.manager); strategy.setStakingSlippage(0);
        // Request a credit from the multistrategy
        _requestCredit(1_000 ether);
        _;
    }

    modifier whenNoDebtRepayment() {
        _;
    }

    modifier whenStrategyMadeGain() {
        // Makes a 100 ether gain (10%)
        strategy.earn(100 ether);
        _;
    }

    modifier whenStrategyMadeLoss() {
        // Makes a 100 ether loss (-10%)
        strategy.lose(100 ether);
        _;
    }

    function test_SendReport_ZeroDebtRepayWithGain() 
        external
        whenCallerOwner
        whenContractNotPaused
        whenSlippageLimitRespected
        whenNoDebtRepayment
        whenStrategyMadeGain
    {
        vm.prank(users.manager); strategy.sendReport(0);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 1000 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyAssets = 1090 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_ZeroDebtRepayWithLoss()
        external
        whenCallerOwner
        whenContractNotPaused
        whenSlippageLimitRespected
        whenNoDebtRepayment
        whenStrategyMadeLoss
    {
        vm.prank(users.manager); strategy.sendReport(0);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 900 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyAssets = 900 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    modifier whenDebtRepayment() {
        _;
    }

    function test_SendReport_DebtRepayNoExcessDebtWithGain()
        external
        whenCallerOwner
        whenContractNotPaused
        whenSlippageLimitRespected
        whenDebtRepayment
        whenStrategyMadeGain
    {
        vm.prank(users.manager); strategy.sendReport(1000 ether);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 1000 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyAssets = 1090 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_DebtRepayNoExcessDebtWithLoss()
        external
        whenCallerOwner
        whenContractNotPaused
        whenSlippageLimitRespected
        whenDebtRepayment
        whenStrategyMadeLoss
    {
        vm.prank(users.manager); strategy.sendReport(1000 ether);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 900 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyAssets = 900 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    modifier whenStrartegyHasDebtExcess () {
        // Set the strategy debt ratio to 0, se we can repay the debt
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);
        _;
    }


    function test_SendReport_DebtRepayExcessDebtWithGain()
        external
        whenCallerOwner
        whenContractNotPaused
        whenSlippageLimitRespected
        whenDebtRepayment
        whenStrartegyHasDebtExcess
        whenStrategyMadeGain
    {
        vm.prank(users.manager); strategy.sendReport(1000 ether);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyAssets = 1090 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_DebtRepayExcessDebtWithLoss()
        external
        whenCallerOwner
        whenContractNotPaused
        whenSlippageLimitRespected
        whenDebtRepayment
        whenStrartegyHasDebtExcess
        whenStrategyMadeLoss
    {
        // Note that we're only withdrawing 900 ether. Withdrawing more than totalAssets would revert
        // with InsufficientBalance
        vm.prank(users.manager); strategy.sendReport(900 ether);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyAssets = 900 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }
}