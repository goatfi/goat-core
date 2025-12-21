// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract SendReport_Integration_Concrete_Test is Adapter_Base_Test {

    uint256 depositAmount = 1000 ether;
    uint256 gain = 100 ether;
    uint256 loss = 100 ether;
    uint256 profit = 90 ether;

    function test_RevertWhen_CallerNotOwner() external {
        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.requestCredit();
    }

    modifier whenCallerOwner() {
        _;
    }

    function test_RevertWhen_SlippageLimitNotRespected()
        external
        whenCallerOwner
    {
        vm.prank(users.manager); strategy.setSlippageLimit(1_000);
        vm.prank(users.manager); strategy.setStakingSlippage(1_500);

        _requestCredit(depositAmount);

        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);

        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 900 ether, 850 ether));
        vm.prank(users.manager); strategy.sendReport(type(uint256).max);
    }

    modifier whenSlippageLimitRespected() {
        _requestCredit(depositAmount);
        _;
    }

    modifier whenStrategyMadeGain() {
        strategy.earn(gain);
        _;
    }

    modifier whenStrategyMadeLoss() {
        strategy.lose(loss);
        _;
    }

    function test_SendReport_ZeroRepay_WithGain() 
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrategyMadeGain
    {
        vm.prank(users.manager); strategy.sendReport(0);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = depositAmount;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = profit;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_ZeroRepay_WithLoss() 
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrategyMadeLoss
    {
        vm.prank(users.manager); strategy.sendReport(0);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = depositAmount - loss;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert no assets have been sent to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = 0 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_RepayAll_NoExcessDebt_WithGain()
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrategyMadeGain
    {
        vm.prank(users.manager); strategy.sendReport(type(uint256).max);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = depositAmount;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = profit;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_RepayAll_NoExcessDebt_WithLoss()
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrategyMadeLoss
    {
        vm.prank(users.manager); strategy.sendReport(type(uint256).max);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = depositAmount - loss;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert no assets have been sent to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = 0 ether;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    modifier whenStrartegyHasDebtExcess () {
        // Set the strategy debt ratio to 0, se we can repay the debt
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);
        _;
    }

    function test_SendReport_RepayAll_WithDebtExcessDebt_WithGain()
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrartegyHasDebtExcess
        whenStrategyMadeGain
    {
        vm.prank(users.manager); strategy.sendReport(type(uint256).max);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert it has sent the gain to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = depositAmount + profit;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_RepayAll_WithDebtExcessDebt_WithLoss()
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrartegyHasDebtExcess
        whenStrategyMadeLoss
    {
        vm.prank(users.manager); strategy.sendReport(type(uint256).max);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert no assets have been sent to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = depositAmount - loss;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_RepayExact_WithDebtExcess_WithGain() 
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrartegyHasDebtExcess
        whenStrategyMadeGain
    {
        uint256 repayAmount = 500 ether;
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = depositAmount - repayAmount;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert no assets have been sent to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = repayAmount + profit;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }

    function test_SendReport_RepayExact_WithDebtExcess_WithLoss() 
        external
        whenCallerOwner
        whenSlippageLimitRespected
        whenStrartegyHasDebtExcess
        whenStrategyMadeLoss
    {
        uint256 repayAmount = 500 ether;
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        // Assert it has withdrawn the gain
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = depositAmount - repayAmount - loss;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert no assets have been sent to the multistrategy
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = repayAmount;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy assets");
    }
}