// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Withdraw_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotMultistrategy() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotMultistrategy.selector, users.bob));
        vm.prank(users.bob); strategy.withdraw(1_000 ether);
    }

    modifier whenCallerMultistrategy() {
        _;
    }

    function test_RevertWhen_ContractPaused() external whenCallerMultistrategy {
        vm.prank(users.guardian); strategy.pause();

        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(address(multistrategy)); strategy.withdraw(1_000 ether);
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
        strategy.setStakingSlippage(1_500);

        _requestCredit(1_000 ether);

        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 900 ether, 850 ether));
        vm.prank(address(multistrategy)); strategy.withdraw(1_000 ether);
    }

    modifier whenSlippageLimitRespected() {
        _;
    }

    function test_Withdraw_PositiveSlippage() 
        external
        whenCallerMultistrategy
        whenContractNotPaused
        whenSlippageLimitRespected
    {
        uint256 amount = 1_000 ether;
        _requestCredit(amount);
        strategy.setStakingSurplus(100); // 1% extra

        // Make a withdraw
        vm.prank(address(multistrategy)); uint256 withdrawn = strategy.withdraw(amount);

        // Assert the strategy holds the surplus
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 10 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert the multistrategy has the assets in balance
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = withdrawn;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy balance");

        // Assert that withdrawn is correct
        assertEq(withdrawn, amount, "withrdraw, return");
    }

    function test_Withdraw_Exact() 
        external
        whenCallerMultistrategy
        whenContractNotPaused
        whenSlippageLimitRespected
    {
        uint256 amount = 1_000 ether;
        _requestCredit(amount);

        vm.prank(address(multistrategy)); uint256 withdrawn = strategy.withdraw(amount);

        // Assert the strategy no longer has the assets
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert the multistrategy has the assets in balance
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = withdrawn;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy balance");

        // Assert that withdrawn is correct
        assertEq(withdrawn, amount, "withrdraw, return");
    }

    function test_Withdraw_NegativeSlippage() 
        external
        whenCallerMultistrategy
        whenContractNotPaused
        whenSlippageLimitRespected
    {
        // Set the slippage limit of the strategy to 1%
        vm.prank(users.manager); strategy.setSlippageLimit(100);

        // Set the staking slippage to be 0.5%
        strategy.setStakingSlippage(50);

        uint256 amount = 1_000 ether;
        _requestCredit(amount);

        // Make a withdraw
        vm.prank(address(multistrategy)); uint256 withdrawn = strategy.withdraw(amount);

        // Assert the strategy no longer has the assets
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert the multistrategy has the assets in balance
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = withdrawn;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy balance");

        // Assert that withdrawn is correct
        assertEq(withdrawn, 995 ether, "withrdraw, return");

        // Assert the strategy has more debt that totalassets
        uint256 strategyTotalDebt = multistrategy.strategyTotalDebt(address(strategy));
        assertGt(strategyTotalDebt, strategy.totalAssets(), "withraw, strategy debt compared to total assets");
    }
}