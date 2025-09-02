// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Withdraw_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotMultistrategy() external {
        // Expect it to revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotMultistrategy.selector, users.bob));
        vm.prank(users.bob); strategy.withdraw(1_000 ether);
    }

    modifier whenCallerMultistrategy() {
        _;
    }

    function test_RevertWhen_ContractPaused() external whenCallerMultistrategy {
        vm.prank(users.guardian); strategy.pause();

        // Expect it to revert
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
        // Set the slippage limit of the strategy to 10%
        vm.prank(users.manager); strategy.setSlippageLimit(1_000);

        // Set the staking slippage to be 15%
        strategy.setStakingSlippage(1_500);

        // Request a credit from the multistrategy
        _requestCredit(1_000 ether);

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 900 ether, 850 ether));
        vm.prank(address(multistrategy)); strategy.withdraw(1_000 ether);
    }

    modifier whenSlippageLimitRespected() {
        _;
    }

    function test_Withdraw() 
        external
        whenCallerMultistrategy
        whenContractNotPaused
        whenSlippageLimitRespected
    {
        // Set the slippage limit of the strategy to 1%
        vm.prank(users.manager); strategy.setSlippageLimit(100);

        // Set the staking slippage to be 0.5%
        strategy.setStakingSlippage(50);

        // Request a credit from the multistrategy
        _requestCredit(1_000 ether);

        // Make a withdraw
        vm.prank(address(multistrategy)); uint256 withdrawn = strategy.withdraw(1_000 ether);

        // Assert the strategy no longer has the assets
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 0;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "withdraw, strategy assets");

        // Assert the multistrategy has the assets in balance
        uint256 actualMultistrategyAssets = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyAssets = withdrawn;
        assertEq(actualMultistrategyAssets, expectedMultistrategyAssets, "withdraw, multistrategy balance");
    }
}