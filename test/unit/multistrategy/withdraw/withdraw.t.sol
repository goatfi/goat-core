// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Withdraw_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 deposit = 1000 ether;
    uint256 amountToWithdraw;

    // Addresses for the mock strategies
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

    function test_RevertWhen_CallerNotEnoughSharesToCoverWithdraw() external {
        amountToWithdraw = 1000 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(ERC4626.ERC4626ExceededMaxWithdraw.selector, users.bob, amountToWithdraw, 0));
        multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    modifier whenCallerHasEnoughSharesToCoverWithdraw() {
        _userDeposit(users.bob, deposit);
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenCallerHasEnoughSharesToCoverWithdraw
    {
        amountToWithdraw = 0;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAmount.selector, amountToWithdraw));
        multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    modifier whenAmountGreaterThanZero() {
        _;
    }

    modifier whenMultistrategyBalanceLowerThanWithdrawAmount() {
        strategyOne = _createAndAddAdapter(5_000, 0, type(uint256).max);
        strategyTwo = _createAndAddAdapter(2_000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        vm.prank(users.manager); strategyTwo.requestCredit();
        _;
    }

    function test_RevertWhen_SlippageOnWithdrawGreaterThanSlippageLimit() 
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount
    {
        strategyTwo.setStakingSlippage(5_000);

        amountToWithdraw = 1000 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 200 ether, 100 ether));
        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    /// @dev To revert when the withdraw needs more shares to cover the withdraw than initially thought
    function test_RevertWhen_SharesSlippage()
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount
    {   
        vm.prank(users.manager); strategyOne.setSlippageLimit(200);
        strategyOne.setStakingSlippage(100);

        amountToWithdraw = 800 ether;

        // Expect a revert
        vm.expectRevert();
        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    function test_Withdraw_WithdrawOrderFull() 
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount 
    {   
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategyOne), 1_000);
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategyTwo), 1_000);
        vm.prank(users.manager); strategyOne.sendReport(type(uint256).max);
        vm.prank(users.manager); strategyTwo.sendReport(type(uint256).max);
        for(uint i = 0; i < 8; ++i) {
            MockStrategyAdapter newAdapter = _createAndAddAdapter(1_000, 0 , 1000 ether);
            vm.prank(users.manager); newAdapter.requestCredit();
        }
        amountToWithdraw = 1000 ether;

        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }


    modifier whenWithdrawOrderEndReached() {
        _;
    }

    modifier whenNotEnoughBalanceToCoverWithdraw() {
        // Remove slippage protection
        vm.prank(users.manager); strategyTwo.setSlippageLimit(10_000);
        // Set the staking slippage to 50%. If a user wants to withdraw 1000 tokens, the staking
        // will only return 500 tokens
        (strategyTwo).setStakingSlippage(5_000);
        _;
    }

    /// @dev Test case where it reaches the end of the withdraw queue but it doesn't
    /// have enough funds to cover the withdraw.
    function test_RevertWhen_QueueEndNoBalanceToCoverWithdraw() 
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount
        whenWithdrawOrderEndReached
        whenNotEnoughBalanceToCoverWithdraw
    {
        // If the user wants to withdraw everything from the multistrategy, the end of the queue will be hit
        amountToWithdraw = 1000 ether;

        vm.expectRevert(abi.encodeWithSelector(Errors.InsufficientBalance.selector, amountToWithdraw, 900 ether));
        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);
    }

    /// @dev Test case where it reaches the end of the withdraw queue and it has enough
    /// funds to cover the withdraw
    function test_Withdraw_QueueEnd() 
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount
        whenWithdrawOrderEndReached
    {
        amountToWithdraw = 1000 ether;

        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = amountToWithdraw;
        assertEq(actualUserBalance, expectedUserBalance, "withdraw, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = multistrategy.balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - amountToWithdraw;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "withdraw, user shares balance");

        // Assert multistrategy reserves.
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "withdraw, multistrategy balance");

        // Assert strategy_one assets.
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 0;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "withdraw, strategy one assets");

        // Assert strategy_two assets.
        uint256 actualStrategyTwoAssets = strategyTwo.totalAssets();
        uint256 expectedStrategyTwoAssets = 0;
        assertEq(actualStrategyTwoAssets, expectedStrategyTwoAssets, "withdraw, strategy two assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = deposit - amountToWithdraw;
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "withdraw, multistrategy total debt");

        // Assert strategy_one totalDebt
        uint256 actualStrategyOneDebt = multistrategy.strategyTotalDebt(address(strategyOne));
        uint256 expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "withdraw, strategy one debt");

        // Assert strategy_two totalDebt
        uint256 actualStrategyTwoDebt = multistrategy.strategyTotalDebt(address(strategyTwo));
        uint256 expectedStrategyTwoDebt = 0 ether;
        assertEq(actualStrategyTwoDebt, expectedStrategyTwoDebt, "withdraw, strategy two debt");
    }

    /// @dev Test case where a strategy with priority in the withdraw order has no debt
    /// so the withdraw process has to jump to the next strategy.
    function test_Withdraw_StrategyWithNoFundsIncludedInOrder()
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount
    {
        // Trigger a withdraw so it empties the first strategy in the order.
        amountToWithdraw = 800 ether;

        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);

        // Assert strategy one has no debt
        uint256 actualStrategyOneDebt = multistrategy.strategyTotalDebt(address(strategyOne));
        uint256 expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "withdraw, strategy one debt");

        // Trigger a second withdraw
        amountToWithdraw = 100 ether;
        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = 900 ether;
        assertEq(actualUserBalance, expectedUserBalance, "withdraw, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = multistrategy.balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - 900 ether;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "withdraw, user shares balance");

        // Assert multistrategy reserves.
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "withdraw, multistrategy balance");

        // Assert strategy_one assets.
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 0;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "withdraw, strategy one assets");

        // Assert strategy_two assets.
        uint256 actualStrategyTwoAssets = strategyTwo.totalAssets();
        uint256 expectedStrategyTwoAssets = 100 ether;
        assertEq(actualStrategyTwoAssets, expectedStrategyTwoAssets, "withdraw, strategy two assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = 100 ether;
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "withdraw, multistrategy total debt");

        // Assert strategy_one totalDebt
        actualStrategyOneDebt = multistrategy.strategyTotalDebt(address(strategyOne));
        expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "withdraw, strategy one debt");

        // Assert strategy_two totalDebt
        uint256 actualStrategyTwoDebt = multistrategy.strategyTotalDebt(address(strategyTwo));
        uint256 expectedStrategyTwoDebt = 100 ether;
        assertEq(actualStrategyTwoDebt, expectedStrategyTwoDebt, "withdraw, strategy two debt");
    }

    /// @dev Test case where the withdraw process is started and it gets
    // enough funds to cover the withdraw without reaching the queue end
    function test_Withdraw_NotReachQueueEnd()
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanWithdrawAmount
    {
        amountToWithdraw = 800 ether;

        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = amountToWithdraw;
        assertEq(actualUserBalance, expectedUserBalance, "withdraw, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = multistrategy.balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - amountToWithdraw;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "withdraw, user shares balance");

        // Assert multistrategy reserves.
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "withdraw, multistrategy balance");

        // Assert strategy_one assets
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 0;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "withdraw, strategy one assets");

        // Assert strategy_two assets
        uint256 actualStrategyTwoAssets = strategyTwo.totalAssets();
        uint256 expectedStrategyTwoAssets = 200 ether;
        assertEq(actualStrategyTwoAssets, expectedStrategyTwoAssets, "withdraw, strategy two assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = deposit - amountToWithdraw;
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "withdraw, multistrategy total debt");

        // Assert strategy_one totalDebt
        uint256 actualStrategyOneDebt = multistrategy.strategyTotalDebt(address(strategyOne));
        uint256 expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "withdraw, strategy one debt");

        // Assert strategy_two totalDebt
        uint256 actualStrategyTwoDebt = multistrategy.strategyTotalDebt(address(strategyTwo));
        uint256 expectedStrategyTwoDebt = 200 ether;
        assertEq(actualStrategyTwoDebt, expectedStrategyTwoDebt, "withdraw, strategy two debt");
    }

    modifier whenMultistrategyBalanceHigherOrEqualThanWithdrawAmount() {
        strategyOne = _createAndAddAdapter(5_000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    /// @dev Test case where withdraws can be covered by the reserves in the multistrategy contract
    function test_Withdraw_NoWithdrawProcess()
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
        whenMultistrategyBalanceHigherOrEqualThanWithdrawAmount
    {
        amountToWithdraw = 500 ether;

        vm.prank(users.bob); multistrategy.withdraw(amountToWithdraw, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = amountToWithdraw;
        assertEq(actualUserBalance, expectedUserBalance, "withdraw, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = multistrategy.balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - amountToWithdraw ;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "withdraw, user shares balance");

        // Assert multistrategy reserves
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "withdraw, multistrategy balance");

        // Assert strategy_one assets
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 500 ether;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "withdraw, strategy one assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = deposit - amountToWithdraw;
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "withdraw, multistrategy total debt");

        // Assert strategy_one totalDebt
        uint256 actualStrategyOneDebt = multistrategy.strategyTotalDebt(address(strategyOne));
        uint256 expectedStrategyOneDebt = 500 ether;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "withdraw, strategy one debt");
    }

    function test_RevertWhen_CallerNotOwnerAndAllowanceInsufficient()
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
    {
        amountToWithdraw = 500 ether;
        uint256 sharesNeeded = multistrategy.previewWithdraw(amountToWithdraw);

        // Allowance is 0 by default
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20InsufficientAllowance(address,uint256,uint256)")), users.alice, 0, sharesNeeded));
        vm.prank(users.alice); multistrategy.withdraw(amountToWithdraw, users.alice, users.bob);
    }

    function test_Withdraw_CallerNotOwnerWithSufficientAllowance()
        external
        whenContractNotPaused
        whenCallerHasEnoughSharesToCoverWithdraw
        whenAmountGreaterThanZero
    {
        amountToWithdraw = 500 ether;
        uint256 sharesNeeded = multistrategy.previewWithdraw(amountToWithdraw);
        uint256 initialAllowance = sharesNeeded + 100 ether; // more than needed

        vm.prank(users.bob); multistrategy.approve(users.alice, initialAllowance);

        uint256 initialAliceBalance = dai.balanceOf(users.alice);
        uint256 initialBobShares = multistrategy.balanceOf(users.bob);

        vm.prank(users.alice); multistrategy.withdraw(amountToWithdraw, users.alice, users.bob);

        // Assert allowance decreased
        uint256 finalAllowance = multistrategy.allowance(users.bob, users.alice);
        assertEq(finalAllowance, initialAllowance - sharesNeeded, "allowance decrease");

        // Assert alice received assets
        uint256 finalAliceBalance = dai.balanceOf(users.alice);
        assertEq(finalAliceBalance, initialAliceBalance + amountToWithdraw, "alice balance");

        // Assert bob shares decreased
        uint256 finalBobShares = multistrategy.balanceOf(users.bob);
        assertEq(finalBobShares, initialBobShares - sharesNeeded, "bob shares");
    }
}