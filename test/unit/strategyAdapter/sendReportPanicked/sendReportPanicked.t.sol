// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";

contract SendReportPanicked_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.sendReportPanicked();
    }

    modifier whenCallerOwner() {
        _;
    }

    function test_RevertWhen_ContractNotPaused()
        external
        whenCallerOwner
    {
        vm.expectRevert(abi.encodeWithSelector(Pausable.ExpectedPause.selector));
        vm.prank(users.manager); strategy.sendReportPanicked();
    }

    modifier whenContractPaused() {
        vm.prank(users.guardian); strategy.panic();
        _;
    }

    modifier whenGain(uint256 _amount) {
        _requestCredit(1000 ether);
        strategy.earn(_amount);
        _;
    }

    modifier whenLoss(uint256 _amount) {
        _requestCredit(1000 ether);
        strategy.lose(_amount);
        _;
    }

    function test_SendReportPanicked_ZeroCurrentAssets()
        external
        whenCallerOwner
        whenLoss(1000 ether)
        whenContractPaused
    {

        vm.prank(users.manager); strategy.sendReportPanicked();

        // Assert that the strategy repaid 0 tokens
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert that the strategy report a 0 gain
        uint256 actualFeeRecipientBalance = IERC20(strategy.asset()).balanceOf(users.feeRecipient);
        uint256 expectedFeeRecipientBalance = 0;
        assertEq(actualFeeRecipientBalance, expectedFeeRecipientBalance, "sendReportPanicked, fee recipient balance");

        // Assert the debt of this strategy is now 0.
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyDebt = 0;
        assertEq(actualStrategyDebt, expectedStrategyDebt, "sendReportPanicked, strategy debt");

        // Assert that the loss has been reported
        uint256 actualLoss = (multistrategy.getStrategyParameters(address(strategy))).totalLoss;
        uint256 expectedLoss = 1000 ether;
        assertEq(actualLoss, expectedLoss, "sendReportPanicked, loss");
    }

    modifier whenCurrentAssetsNotZero() {
        _;
    }

    function test_SendReportPanicked_StrategyNotRetired_Gain()
        external
        whenCallerOwner
        whenGain(100 ether)
        whenContractPaused
        whenCurrentAssetsNotZero
    {
        vm.prank(users.manager); strategy.sendReportPanicked();

        // Assert that the strategy repaid the gain
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 90 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert that the strategy has the same balance of assets as debt amount
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 actualStrategyTotalAssets = IERC20(strategy.asset()).balanceOf(address(strategy));
        assertEq(actualStrategyDebt, actualStrategyTotalAssets, "sendReportPanicked, assets and debt match");

        // Assert that the gain has been reported
        uint256 actualGain = (multistrategy.getStrategyParameters(address(strategy))).totalGain;
        uint256 expectedGain = 100 ether;
        assertEq(actualGain, expectedGain, "sendReportPanicked, gain");
    }

    function test_SendReportPanicked_StrategyNotRetired_Loss()
        external
        whenCallerOwner
        whenLoss(100 ether)
        whenContractPaused
        whenCurrentAssetsNotZero
    {
        vm.prank(users.manager); strategy.sendReportPanicked();

        // Assert that the strategy hasn't repaid anything
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert that the strategy has the same balance of assets as debt amount
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 actualStrategyTotalAssets = IERC20(strategy.asset()).balanceOf(address(strategy));
        assertEq(actualStrategyDebt, actualStrategyTotalAssets, "sendReportPanicked, assets and debt match");

        // Assert that the loss has been reported
        uint256 actualLoss = (multistrategy.getStrategyParameters(address(strategy))).totalLoss;
        uint256 expectedLoss = 100 ether;
        assertEq(actualLoss, expectedLoss, "sendReportPanicked, loss");
    }

    modifier whenStrategyRetired() {
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 0);
        _;
    }

    function test_SendReportPanicked_Gain()
        external
        whenCallerOwner
        whenGain(100 ether)
        whenContractPaused
        whenCurrentAssetsNotZero
        whenStrategyRetired
    {
        vm.prank(users.manager); strategy.sendReportPanicked();

        // Assert that the strategy repaid the everything
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 1090 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert that the strategy total debt is 0
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 0;
        assertEq(actualStrategyDebt, expectedStrategyTotalDebt, "sendReportPanicked, strategy total debt");

        // Assert that the strategy total assets is 0
        uint256 actualStrategyTotalAssets = IERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 expectedStrategyTotalAssets = 0;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "sendReportPanicked, strategy total assets");

        // Assert that the gain has been reported
        uint256 actualGain = (multistrategy.getStrategyParameters(address(strategy))).totalGain;
        uint256 expectedGain = 100 ether;
        assertEq(actualGain, expectedGain, "sendReportPanicked, gain");
    }

    function test_SendReportPanicked_Loss()
        external
        whenCallerOwner
        whenLoss(100 ether)
        whenContractPaused
        whenCurrentAssetsNotZero
        whenStrategyRetired
    {
        vm.prank(users.manager); strategy.sendReportPanicked();

        // Assert that the strategy repaid the loss
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 900 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert that the strategy total debt is 0
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyTotalDebt = 0;
        assertEq(actualStrategyDebt, expectedStrategyTotalDebt, "sendReportPanicked, strategy total debt");

        // Assert that the strategy total assets is 0
        uint256 actualStrategyTotalAssets = IERC20(strategy.asset()).balanceOf(address(strategy));
        uint256 expectedStrategyTotalAssets = 0;
        assertEq(actualStrategyTotalAssets, expectedStrategyTotalAssets, "sendReportPanicked, strategy total assets");

        // Assert that the loss has been reported
        uint256 actualLoss = (multistrategy.getStrategyParameters(address(strategy))).totalLoss;
        uint256 expectedLoss = 100 ether;
        assertEq(actualLoss, expectedLoss, "sendReportPanicked, loss");
    }
}