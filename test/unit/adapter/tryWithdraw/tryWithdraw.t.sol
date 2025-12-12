// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract TryWithdraw_Integration_Concrete_Test is Adapter_Base_Test {
    function test_TryWithdraw_ZeroAmount() external {
        strategy.tryWithdraw(0);

        uint256 actualWithdraw = dai.balanceOf(address(strategy));
        uint256 expectedWithdrawn = 0;
        assertEq(actualWithdraw, expectedWithdrawn, "tryWithdraw, zero amount");
    }

    modifier whenAmountGreaterThanZero() {
        _;
    }

    function test_TryWithdraw_AmountLowerThanBalance() external whenAmountGreaterThanZero {
        _requestCredit(1000 ether);

        dai.mint(address(strategy), 10 ether);
        strategy.tryWithdraw(5 ether);

        uint256 actualStrategyBalance = dai.balanceOf(address(strategy));
        uint256 expectedStrategyBalance = 10 ether;
        assertEq(actualStrategyBalance, expectedStrategyBalance, "tryWithdraw, amount lower than balance");
    }

    function test_TryWithdraw_EqualToBalance() external whenAmountGreaterThanZero {
        _requestCredit(1000 ether);

        dai.mint(address(strategy), 10 ether);
        strategy.tryWithdraw(10 ether);

        uint256 actualStrategyBalance = dai.balanceOf(address(strategy));
        uint256 expectedStrategyBalance = 10 ether;
        assertEq(actualStrategyBalance, expectedStrategyBalance, "tryWithdraw, amount equal to balance");
    }
    
    function test_RevertWhen_CurrentBalanceLowerThanDesiredBalance() 
        external
        whenAmountGreaterThanZero
    {   
        // Set slippage limit to 10%
        vm.prank(users.manager); strategy.setSlippageLimit(1000);

        // Set staking slippage to 15%
        strategy.setStakingSlippage(1500);
        _requestCredit(1000 ether);

        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 900 ether, 850 ether));
        strategy.tryWithdraw(1000 ether);
    }

    modifier whenCurrentBalanceHigherThanDesiredBalance() {
        _;
    }

    function test_TryWithdraw() 
        external
        whenAmountGreaterThanZero
        whenCurrentBalanceHigherThanDesiredBalance
    {
        _requestCredit(1000 ether);

        strategy.tryWithdraw(1000 ether);

        uint256 actualWithdraw = dai.balanceOf(address(strategy));
        uint256 expectedWithdrawn = 1000 ether;
        assertEq(actualWithdraw, expectedWithdrawn, "tryWithdraw, zero amount");
    }
}