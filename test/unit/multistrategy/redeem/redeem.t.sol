// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Redeem_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 deposit = 1000 ether;
    uint256 amountToRedeem;

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
        amountToRedeem = 1000 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ERC4626ExceededMaxRedeem.selector, users.bob, amountToRedeem, 0));
        multistrategy.redeem(amountToRedeem, users.bob, users.bob);
    }

    modifier whenHasCallerEnoughSharesToCoverRedeem() {
        _userDeposit(users.bob, deposit);
        _;
    }

    function test_RevertWhen_AmountIsZero()
        external
        whenHasCallerEnoughSharesToCoverRedeem
    {
        amountToRedeem = 0;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAmount.selector, amountToRedeem));
        multistrategy.redeem(amountToRedeem, users.bob, users.bob);
    }

    modifier whenAmountGreaterThanZero() {
        _;
    }

    modifier whenMultistrategyBalanceLowerThanRedeemAmount() {
        strategyOne = _createAndAddAdapter(5_000, 0, type(uint256).max);
        strategyTwo = _createAndAddAdapter(2_000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        vm.prank(users.manager); strategyTwo.requestCredit();
        _;
    }

    function test_RevertWhen_SlippageOnWithdrawGreaterThanSlippageLimit() 
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanRedeemAmount
    {
        strategyTwo.setStakingSlippage(5_000);

        amountToRedeem = 1000 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 200 ether, 100 ether));
        vm.prank(users.bob); multistrategy.redeem(amountToRedeem, users.bob, users.bob);
    }

    /// @dev To revert when the redeem returns less assets than initially thought
    function test_RevertWhen_AssetsSlippage()
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanRedeemAmount
    {   
        vm.prank(users.manager); strategyOne.setSlippageLimit(200);
        strategyOne.setStakingSlippage(100);

        amountToRedeem = 800 ether;

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 800 ether, 796 ether));
        vm.prank(users.bob);  multistrategy.redeem(amountToRedeem, users.bob, users.bob);
    }

    modifier whenWithdrawOrderEndReached() {
        _;
    }

    modifier whenNotEnoughBalanceToCoverRedeem() {
        
        _;
    }

    /// @dev Test case where it reaches the end of the withdraw queue but it doesn't
    /// have enough funds to cover the withdraw.
    function test_RevertWhen_QueueEndNoBalanceToCoverRedeem()
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanRedeemAmount
        whenWithdrawOrderEndReached
        whenNotEnoughBalanceToCoverRedeem
    {
        
    }

    /// @dev Test case where it reaches the end of the withdraw queue and it has enough
    /// funds to cover the redeem
    function test_Redeem_QueueEnd() 
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanRedeemAmount
        whenWithdrawOrderEndReached
    {
        amountToRedeem = 1000 ether;

        vm.prank(users.bob);  multistrategy.redeem(amountToRedeem, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = amountToRedeem;
        assertEq(actualUserBalance, expectedUserBalance, "redeem, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = IERC20(address(multistrategy)).balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit  - amountToRedeem ;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "redeem, user shares balance");

        // Assert multistrategy reserves.
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "redeem, multistrategy balance");

        // Assert strategy_one assets.
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 0;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "redeem, strategy one assets");

        // Assert strategy_two assets.
        uint256 actualStrategyTwoAssets = strategyTwo.totalAssets();
        uint256 expectedStrategyTwoAssets = 0;
        assertEq(actualStrategyTwoAssets, expectedStrategyTwoAssets, "redeem, strategy two assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = (deposit) - (amountToRedeem);
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "redeem, multistrategy total debt");

        // Assert strategy_one totalDebt
        uint256 actualStrategyOneDebt = multistrategy.getStrategyParameters(address(strategyOne)).totalDebt;
        uint256 expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "redeem, strategy one debt");

        // Assert strategy_two totalDebt
        uint256 actualStrategyTwoDebt = multistrategy.getStrategyParameters(address(strategyTwo)).totalDebt;
        uint256 expectedStrategyTwoDebt = 0 ether;
        assertEq(actualStrategyTwoDebt, expectedStrategyTwoDebt, "redeem, strategy two debt");
    }

    /// @dev Test case where a strategy with priority in the withdraw order has no debt
    /// so the withdraw process has to jump to the next strategy.
    function test_Redeem_StrategyWithNoFundsIncludedInOrder()
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanRedeemAmount
    {
        // Trigger a redeem so it empties the first strategy in the order.
        amountToRedeem = 800 ether;

        vm.prank(users.bob); multistrategy.redeem(amountToRedeem, users.bob, users.bob);

        // Assert strategy one has no debt
        uint256 actualStrategyOneDebt = multistrategy.getStrategyParameters(address(strategyOne)).totalDebt;
        uint256 expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "redeem, strategy one debt");

        // Trigger a second withdraw
        amountToRedeem = 100 ether;
        vm.prank(users.bob); multistrategy.redeem(amountToRedeem , users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = 900 ether;
        assertEq(actualUserBalance, expectedUserBalance, "redeem, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = IERC20(address(multistrategy)).balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - 900 ether;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "redeem, user shares balance");

        // Assert multistrategy reserves.
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "redeem, multistrategy balance");

        // Assert strategy_one assets.
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 0;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "redeem, strategy one assets");

        // Assert strategy_two assets.
        uint256 actualStrategyTwoAssets = strategyTwo.totalAssets();
        uint256 expectedStrategyTwoAssets = 100 ether;
        assertEq(actualStrategyTwoAssets, expectedStrategyTwoAssets, "redeem, strategy two assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = 100 ether;
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "redeem, multistrategy total debt");

        // Assert strategy_one totalDebt
        actualStrategyOneDebt = multistrategy.getStrategyParameters(address(strategyOne)).totalDebt;
        expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "redeem, strategy one debt");

        // Assert strategy_two totalDebt
        uint256 actualStrategyTwoDebt = multistrategy.getStrategyParameters(address(strategyTwo)).totalDebt;
        uint256 expectedStrategyTwoDebt = 100 ether;
        assertEq(actualStrategyTwoDebt, expectedStrategyTwoDebt, "redeem, strategy two debt");
    }

    /// @dev Test case where the withdraw process is started and it gets
    // enough funds to cover the redeem without reaching the queue end
    function test_Redeem_NotReachQueueEnd()
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceLowerThanRedeemAmount
    {
        amountToRedeem = 800 ether;

        vm.prank(users.bob); multistrategy.redeem(amountToRedeem, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = amountToRedeem;
        assertEq(actualUserBalance, expectedUserBalance, "redeem, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = IERC20(address(multistrategy)).balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - amountToRedeem;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "redeem, user shares balance");

        // Assert multistrategy reserves.
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "redeem, multistrategy balance");

        // Assert strategy_one assets
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 0;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "redeem, strategy one assets");

        // Assert strategy_two assets
        uint256 actualStrategyTwoAssets = strategyTwo.totalAssets();
        uint256 expectedStrategyTwoAssets = 200 ether;
        assertEq(actualStrategyTwoAssets, expectedStrategyTwoAssets, "redeem, strategy two assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = (deposit) - (amountToRedeem);
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "redeem, multistrategy total debt");

        // Assert strategy_one totalDebt
        uint256 actualStrategyOneDebt = multistrategy.getStrategyParameters(address(strategyOne)).totalDebt;
        uint256 expectedStrategyOneDebt = 0;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "redeem, strategy one debt");

        // Assert strategy_two totalDebt
        uint256 actualStrategyTwoDebt = multistrategy.getStrategyParameters(address(strategyTwo)).totalDebt;
        uint256 expectedStrategyTwoDebt = 200 ether;
        assertEq(actualStrategyTwoDebt, expectedStrategyTwoDebt, "redeem, strategy two debt");
    }

    modifier whenMultistrategyBalanceHigherOrEqualThanRedeemAmount() {
        strategyOne = _createAndAddAdapter(5_000, 0, type(uint256).max);

        vm.prank(users.manager); strategyOne.requestCredit();
        _;
    }

    /// @dev Test case where redeem can be covered by the reserves in the multistrategy contract
    function test_Redeem_NoWithdrawProcess() 
        external
        whenContractNotPaused
        whenHasCallerEnoughSharesToCoverRedeem
        whenAmountGreaterThanZero
        whenMultistrategyBalanceHigherOrEqualThanRedeemAmount
    {
        amountToRedeem = 500 ether;

        vm.prank(users.bob); multistrategy.redeem(amountToRedeem, users.bob, users.bob);

        // Assert the user balance
        uint256 actualUserBalance = dai.balanceOf(users.bob);
        uint256 expectedUserBalance = amountToRedeem;
        assertEq(actualUserBalance, expectedUserBalance, "redeem, user balance");

        // Assert the user shares balance
        uint256 actualUserSharesBalance = IERC20(address(multistrategy)).balanceOf(users.bob);
        uint256 expectedUserSharesBalance = deposit - amountToRedeem;
        assertEq(actualUserSharesBalance, expectedUserSharesBalance, "redeem, user shares balance");

        // Assert multistrategy reserves
        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 0;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "redeem, multistrategy balance");

        // Assert strategy_one assets
        uint256 actualStrategyOneAssets = strategyOne.totalAssets();
        uint256 expectedStrategyOneAssets = 500 ether;
        assertEq(actualStrategyOneAssets, expectedStrategyOneAssets, "redeem, strategy one assets");

        // Assert multistrategy totalDebt
        uint256 actualMultistrategyDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyDebt = (deposit) - (amountToRedeem);
        assertEq(actualMultistrategyDebt, expectedMultistrategyDebt, "redeem, multistrategy total debt");

        // Assert strategy_one totalDebt
        uint256 actualStrategyOneDebt = multistrategy.getStrategyParameters(address(strategyOne)).totalDebt;
        uint256 expectedStrategyOneDebt = 500 ether;
        assertEq(actualStrategyOneDebt, expectedStrategyOneDebt, "redeem, strategy one debt");
    }
}