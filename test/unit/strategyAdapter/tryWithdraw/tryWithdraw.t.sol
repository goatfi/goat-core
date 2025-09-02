// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract TryWithdraw_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_TryWithdraw_ZeroAmount() external {
        strategy.tryWithdraw(0);

        uint256 actualWithdraw = dai.balanceOf(address(strategy));
        uint256 expectedWithdrawn = 0;
        assertEq(actualWithdraw, expectedWithdrawn, "tryWithdraw, zero amount");
    }

    modifier whenAmountGreaterThanZero() {
        _;
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

        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 900 ether, 850 ether));
        strategy.tryWithdraw(1000 ether);
    }

    modifier whenCurrentBalanceHigherThanDesiredBalance() {
        _;
    }

    function test_Withdraw() 
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