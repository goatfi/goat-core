// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract AskReport_Integration_Concrete_Test is Adapter_Base_Test {

    function test_RevertWhen_CallerNotMultistrategy() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotMultistrategy.selector, users.bob));
        vm.prank(users.bob); strategy.askReport();
    }

    modifier whenCallerMultistrategy() {
        _;
    }

    function test_RevertWhen_ContractPaused() external whenCallerMultistrategy {
        vm.prank(users.guardian); strategy.pause();
        
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(address(multistrategy)); strategy.askReport();
    }

    modifier whenContractNotPaused() {
        _;
    }

    function test_RevertWhen_SlippageLimitExceeded() 
        external
        whenCallerMultistrategy
        whenContractNotPaused
    {
        vm.prank(users.manager); strategy.setSlippageLimit(1_000);
        vm.prank(users.manager); strategy.setStakingSlippage(1_500);

        // Request a credit from the multistrategy
        _requestCredit(1_000 ether);

        // Earn some tokens so we can test the slippage when withdrawing the gain
        strategy.earn(100 ether);
        
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 90 ether, 85 ether));
        vm.prank(address(multistrategy)); strategy.askReport();
    }

    modifier whenSlippageLimitRespected() {
        _;
    }

    function test_AskReport_Gain() 
        external
        whenCallerMultistrategy
        whenContractNotPaused
        whenSlippageLimitRespected
    {
        _requestCredit(1_000 ether);
        strategy.earn(100 ether);

        vm.prank(address(multistrategy)); strategy.askReport();

        // Assert the gain gets withdrawn from the underlying strategy
        uint256 actualUnderlyingStrategyBalance = strategy.totalAssets();
        uint256 expectedUnderlyingStrategyBalance = 1000 ether;
        assertEq(actualUnderlyingStrategyBalance, expectedUnderlyingStrategyBalance, "askReport, underlying strategy balance");

        // Assert the gain gets transferred to the multistrategy
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 90 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert the strategy has the same balance of totalAssets as totalDebt
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        assertEq(actualStrategyDebt, actualStrategyTotalAssets, "sendReportPanicked, assets and debt match");
    }

    function test_AskReport_Loss()
        external
        whenCallerMultistrategy
        whenContractNotPaused
        whenSlippageLimitRespected
    {
        _requestCredit(1_000 ether);
        strategy.lose(100 ether);

        vm.prank(address(multistrategy)); strategy.askReport();

        // Assert the multistrategy doesn't get any gain
        uint256 actualMultistrategyBalance = IERC20(strategy.asset()).balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "sendReportPanicked, multistrategy balance");

        // Assert the strategy has the same balance of totalAssets as totalDebt
        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 actualStrategyTotalAssets = strategy.totalAssets();
        assertEq(actualStrategyDebt, actualStrategyTotalAssets, "sendReportPanicked, assets and debt match");
    }
}