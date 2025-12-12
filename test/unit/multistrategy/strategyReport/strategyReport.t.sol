// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockAdapter } from "../../../mocks/MockAdapter.sol";
import { IMultistrategy } from "src/interfaces/IMultistrategy.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract StrategyReport_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockAdapter strategy;

    uint256 deposit = 1_000 ether;
    uint256 gainAmount;
    uint256 loseAmount;
    uint256 repayAmount;

    function test_RevertWhen_ContractIsPaused() external {
        vm.prank(users.guardian); multistrategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        multistrategy.requestCredit();
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_RevertWhen_CallerNotActiveStrategy()
        external
        whenContractNotPaused    
    {   
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, users.manager));
        vm.prank(users.manager); multistrategy.requestCredit();
    }

    modifier whenCallerActiveStrategy() {
        strategy = _createAndAddAdapter(5_000, 0, type(uint256).max);
        _userDeposit(users.bob, deposit);
        _;
    }

    function test_RevertWhen_StrategyReportsGainAndLoss()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
    {
        repayAmount = 0;
        gainAmount = 100 ether;
        loseAmount = 100 ether;

        vm.expectRevert(abi.encodeWithSelector(Errors.GainLossMismatch.selector));
        vm.prank(address(strategy)); multistrategy.strategyReport(repayAmount, gainAmount, loseAmount);
    }

    modifier whenStrategyOnlyReportsGainOrLoss() {
        _;
    }

    function test_RevertWhen_StrategyLacksBalanceToRepayDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
    {
        repayAmount = 0;
        gainAmount = 100 ether;
        loseAmount = 0;

        vm.expectRevert(abi.encodeWithSelector(Errors.InsufficientBalance.selector, 0, repayAmount + gainAmount));
        vm.prank(address(strategy)); multistrategy.strategyReport(repayAmount, gainAmount, loseAmount);
    }

    modifier whenStrategyHasBalanceToRepay() {
        vm.prank(users.manager); strategy.requestCredit();
        _;
    }

    modifier whenStrategyHasMadeALoss(uint256 _amount) {
        strategy.lose(_amount);
        _;
    }

    modifier whenStrategyHasExceedingDebt() {
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy),  0);
        _;
    }

    /// @dev LockedProfit is 0 here as the strategy still hasn't reported any gain. So any loss
    /// will be higher than the locked profit.
    function test_StrategyReport_LossHigherThanLockedProfit_ExceedingDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
        whenStrategyHasBalanceToRepay()
        whenStrategyHasMadeALoss(100 ether)
        whenStrategyHasExceedingDebt
    {   
        repayAmount = 100 ether;
        gainAmount = 0;
        loseAmount = 100 ether;

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.StrategyReported(address(strategy), repayAmount, gainAmount, loseAmount);

        // Report with [100, 0, 100]
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        // Assert that the loss has been reported
        uint256 actualMultistrategyTotalAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyTotalAssets = deposit - loseAmount;
        assertEq(actualMultistrategyTotalAssets, expectedMultistrategyTotalAssets, "strategyReport multistrategy totalAssets");

        // Assert that the strategy total assets have been reduced by the repayment and lose amount
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        uint256 expectedStrategyTotalAssets = 500 ether - repayAmount - loseAmount;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "strategyReport strategy totalAssets");

        // Assert that locked profit is zero
        uint256 actualLockedProfit = multistrategy.lockedProfit();
        uint256 expectedLockedProfit = 0;
        assertEq(actualLockedProfit, expectedLockedProfit, "strategyReport lockedProfit");

        // Assert that the multistrategy las report has been updated
        uint256 actualMultistrategyLastReport = multistrategy.lastReport();
        uint256 expectedMultistrategyLastReport = block.timestamp;
        assertEq(actualMultistrategyLastReport, expectedMultistrategyLastReport, "strategyReport multistrategy lastReport");

        // Assert that the multistrategy las report has been updated
        uint256 actualStrategyLastReport = multistrategy.getStrategyParameters(address(strategy)).lastReport;
        uint256 expectedStrategyLastReport = block.timestamp;
        assertEq(actualStrategyLastReport, expectedStrategyLastReport, "strategyReport strategy lastReport");

        // Assert that the strategy paid the debt with the balance it made available
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether + repayAmount;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "strategyReport multistrategy balance");
    }

    function test_StrategyReport_LossHigherThanLockedProfit_NoExceedingDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
        whenStrategyHasBalanceToRepay()
        whenStrategyHasMadeALoss(100  ether)
    {
        repayAmount = 0;
        gainAmount = 0;
        loseAmount = 100  ether;

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.StrategyReported(address(strategy), repayAmount, gainAmount, loseAmount);

        // Report with [0, 0, 100]
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        // Assert that the loss has been reported
        uint256 actualMultistrategyTotalAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyTotalAssets = deposit - loseAmount;
        assertEq(actualMultistrategyTotalAssets, expectedMultistrategyTotalAssets, "strategyReport multistrategy totalAssets");

        // Assert that the strategy didn't pay any debt
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "strategyReport multistrategy balance");

        // Assert that the strategy total assets have been reduced by the lose amount
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        uint256 expectedStrategyTotalAssets = 500 ether - loseAmount;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "strategyReport strategy totalAssets");

        // Assert that locked profit is zero
        uint256 actualLockedProfit = multistrategy.lockedProfit();
        uint256 expectedLockedProfit = 0;
        assertEq(actualLockedProfit, expectedLockedProfit, "strategyReport lockedProfit");

        // Assert that the multistrategy las report has been updated
        uint256 actualMultistrategyLastReport = multistrategy.lastReport();
        uint256 expectedMultistrategyLastReport = block.timestamp;
        assertEq(actualMultistrategyLastReport, expectedMultistrategyLastReport, "strategyReport multistrategy lastReport");

        // Assert that the multistrategy las report has been updated
        uint256 actualStrategyLastReport = multistrategy.getStrategyParameters(address(strategy)).lastReport;
        uint256 expectedStrategyLastReport = block.timestamp;
        assertEq(actualStrategyLastReport, expectedStrategyLastReport, "strategyReport strategy lastReport");
    }

    modifier whenThereIsLockedProfit(uint256 _amount) {
        // Report a 100 token gain in order to get some profit locked
        dai.mint(address(strategy), _amount);
        vm.prank(address(strategy)); multistrategy.strategyReport(0, _amount, 0);
        _;
    }

    function test_StrategyReport_LossLowerThanLockedProfit_ExceedingDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
        whenStrategyHasBalanceToRepay()
        whenStrategyHasMadeALoss(10  ether)
        whenThereIsLockedProfit(100  ether)
        whenStrategyHasExceedingDebt
    {   
        repayAmount = 100 ether;
        gainAmount = 0;
        loseAmount = 10 ether;
        uint256 profit = 90 ether;

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.StrategyReported(address(strategy), repayAmount, gainAmount, loseAmount);

        // Report with [100, 0, 10]
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        // Assert that the loss has been reported
        uint256 actualMultistrategyTotalAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyTotalAssets = deposit + profit - loseAmount;
        assertEq(actualMultistrategyTotalAssets, expectedMultistrategyTotalAssets, "strategyReport multistrategy totalAssets");

        // Assert that the strategy paid the debt with the balance it made available
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether + profit + repayAmount;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "strategyReport multistrategy balance");

        // Assert that the strategy total assets have been reduced by the repayment and lose amount
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        uint256 expectedStrategyTotalAssets = 500 ether - repayAmount - loseAmount;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "strategyReport strategy totalAssets");

        // Assert that locked profit is the profit minus the loss
        uint256 actualLockedProfit = multistrategy.lockedProfit();
        uint256 expectedLockedProfit = profit - loseAmount;
        assertEq(actualLockedProfit, expectedLockedProfit, "strategyReport lockedProfit");

        // Assert that the multistrategy las report has been updated
        uint256 actualMultistrategyLastReport = multistrategy.lastReport();
        uint256 expectedMultistrategyLastReport = block.timestamp;
        assertEq(actualMultistrategyLastReport, expectedMultistrategyLastReport, "strategyReport multistrategy lastReport");

        // Assert that the multistrategy las report has been updated
        uint256 actualStrategyLastReport = multistrategy.getStrategyParameters(address(strategy)).lastReport;
        uint256 expectedStrategyLastReport = block.timestamp;
        assertEq(actualStrategyLastReport, expectedStrategyLastReport, "strategyReport strategy lastReport");
    }

    function test_StrategyReport_LossLowerThanLockedProfit_NoExceedingDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
        whenStrategyHasBalanceToRepay()
        whenStrategyHasMadeALoss(10 ether)
        whenThereIsLockedProfit(100 ether)
    {
        repayAmount = 0;
        gainAmount = 0;
        loseAmount = 10 ether;
        uint256 profit = 90 ether;

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.StrategyReported(address(strategy), repayAmount, gainAmount, loseAmount);

        // Report with [100, 0, 10]
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        // Assert that the loss has been reported
        uint256 actualMultistrategyTotalAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyTotalAssets = deposit + profit - loseAmount;
        assertEq(actualMultistrategyTotalAssets, expectedMultistrategyTotalAssets, "strategyReport multistrategy totalAssets");

        // Assert that the strategy paid the debt with the balance it made available
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether + profit;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "strategyReport multistrategy balance");

        // Assert that the strategy total assets have been reduced by the repayment and lose amount
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        uint256 expectedStrategyTotalAssets = 500 ether - loseAmount;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "strategyReport strategy totalAssets");

        // Assert that locked profit is the profit minus the loss
        uint256 actualLockedProfit = multistrategy.lockedProfit();
        uint256 expectedLockedProfit = profit - loseAmount;
        assertEq(actualLockedProfit, expectedLockedProfit, "strategyReport lockedProfit");

        // Assert that the multistrategy las report has been updated
        uint256 actualMultistrategyLastReport = multistrategy.lastReport();
        uint256 expectedMultistrategyLastReport = block.timestamp;
        assertEq(actualMultistrategyLastReport, expectedMultistrategyLastReport, "strategyReport multistrategy lastReport");

        // Assert that the multistrategy las report has been updated
        uint256 actualStrategyLastReport = multistrategy.getStrategyParameters(address(strategy)).lastReport;
        uint256 expectedStrategyLastReport = block.timestamp;
        assertEq(actualStrategyLastReport, expectedStrategyLastReport, "strategyReport strategy lastReport");
    }

    modifier whenStrategyHasMadeAGain(uint256 _amount) {
        strategy.earn(_amount);
        strategy.withdrawFromStaking(_amount);
        _;
    }

    function test_StrategyReport_Gain_ExceedingDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
        whenStrategyHasBalanceToRepay()
        whenStrategyHasMadeAGain(100 ether)
        whenStrategyHasExceedingDebt
    {
        repayAmount = 100 ether;
        gainAmount = 100 ether;
        uint256 fee = Math.mulDiv(gainAmount, multistrategy.performanceFee(), 10_000);

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.StrategyReported(address(strategy), repayAmount, gainAmount, loseAmount);

        // Report with [100, 100, 0]
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        uint256 actualFeeRecipientBalance = dai.balanceOf(multistrategy.protocolFeeRecipient());
        uint256 expectedFeeRecipientBalance = fee;
        assertEq(actualFeeRecipientBalance, expectedFeeRecipientBalance, "strategyReport, fee recipient balance");

        // Assert that the gain has been reported
        uint256 actualMultistrategyTotalAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyTotalAssets = deposit + gainAmount - fee;
        assertEq(actualMultistrategyTotalAssets, expectedMultistrategyTotalAssets, "strategyReport multistrategy totalAssets");

        // Assert that the strategy paid the debt with the balance it made available
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether + repayAmount + gainAmount - fee;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "strategyReport multistrategy balance");

        // Assert that the strategy total assets have been reduced by the repayment
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        uint256 expectedStrategyTotalAssets = 500 ether - repayAmount;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "strategyReport strategy totalAssets");

        // Assert that locked profit is the profit minus the loss
        uint256 actualLockedProfit = multistrategy.lockedProfit();
        uint256 expectedLockedProfit = gainAmount - fee;
        assertEq(actualLockedProfit, expectedLockedProfit, "strategyReport lockedProfit");

        // Assert that the multistrategy las report has been updated
        uint256 actualMultistrategyLastReport = multistrategy.lastReport();
        uint256 expectedMultistrategyLastReport = block.timestamp;
        assertEq(actualMultistrategyLastReport, expectedMultistrategyLastReport, "strategyReport multistrategy lastReport");

        // Assert that the multistrategy las report has been updated
        uint256 actualStrategyLastReport = multistrategy.getStrategyParameters(address(strategy)).lastReport;
        uint256 expectedStrategyLastReport = block.timestamp;
        assertEq(actualStrategyLastReport, expectedStrategyLastReport, "strategyReport strategy lastReport");
    }

    function test_StrategyReport_Gain_NoExceedingDebt()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenStrategyOnlyReportsGainOrLoss
        whenStrategyHasBalanceToRepay()
        whenStrategyHasMadeAGain(100 ether)
    {
        repayAmount = 0;
        gainAmount = 100 ether;
        uint256 fee = Math.mulDiv(gainAmount, multistrategy.performanceFee(), 10_000);

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.StrategyReported(address(strategy), repayAmount, gainAmount, loseAmount);

        // Report with [100, 100, 0]
        vm.prank(users.manager); strategy.sendReport(repayAmount);

        uint256 actualFeeRecipientBalance = dai.balanceOf(multistrategy.protocolFeeRecipient());
        uint256 expectedFeeRecipientBalance = fee;
        assertEq(actualFeeRecipientBalance, expectedFeeRecipientBalance, "strategyReport, fee recipient balance");

        // Assert that the gain has been reported
        uint256 actualMultistrategyTotalAssets = multistrategy.totalAssets();
        uint256 expectedMultistrategyTotalAssets = deposit + gainAmount - fee;
        assertEq(actualMultistrategyTotalAssets, expectedMultistrategyTotalAssets, "strategyReport multistrategy totalAssets");

        // Assert that the strategy paid the debt with the balance it made available
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether + gainAmount - fee;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "strategyReport multistrategy balance");

        // Assert that the strategy total assets have been reduced by the repayment
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        uint256 expectedStrategyTotalAssets = 500 ether;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "strategyReport strategy totalAssets");

        // Assert that the multistrategy las report has been updated
        uint256 actualMultistrategyLastReport = multistrategy.lastReport();
        uint256 expectedMultistrategyLastReport = block.timestamp;
        assertEq(actualMultistrategyLastReport, expectedMultistrategyLastReport, "strategyReport multistrategy lastReport");

        // Assert that the multistrategy las report has been updated
        uint256 actualStrategyLastReport = multistrategy.getStrategyParameters(address(strategy)).lastReport;
        uint256 expectedStrategyLastReport = block.timestamp;
        assertEq(actualStrategyLastReport, expectedStrategyLastReport, "strategyReport strategy lastReport");
    }
}