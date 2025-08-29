// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract RequestCredit_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;

    function test_RevertWhen_ContractIsPaused() external {
        // Pause the multistrategy
        multistrategy.pause();

        // Expect a revert
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
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyNotActive.selector, users.owner));
        multistrategy.requestCredit();
    }

    modifier whenCallerActiveStrategy() {
        strategy = _createAndAddAdapter(5_000, 0 , type(uint256).max);

        _userDeposit(users.bob, 1_000 ether);
        _;
    }

    function test_RequestCredit_NoAvailableCredit()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
    {   
        //Set the debtRatio to 0 so there isn't any credit available
        multistrategy.setStrategyDebtRatio(address(strategy), 0);

        vm.prank(address(strategy)); uint256 actualCredit = multistrategy.requestCredit();

        uint256 expectedCredit = 0;
        assertEq(actualCredit, expectedCredit, "requestCredit, credit");

        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 1_000 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "requestCredit, no availableCredit, multistrategy balance");

        uint256 actualStrategyBalance = dai.balanceOf(address(strategy));
        uint256 expectedStrategyBalance = 0;
        assertEq(actualStrategyBalance, expectedStrategyBalance, "requestCredit, no availableCredit, strategy balance");
    }

    modifier whenCreditAvailable() {
        _;
    }

    function test_RequestCredit() 
        external
        whenContractNotPaused
        whenCallerActiveStrategy
        whenCreditAvailable
    {
        vm.prank(address(strategy)); uint256 actualCredit = multistrategy.requestCredit();

        uint256 expectedCredit = 500 ether;
        assertEq(actualCredit, expectedCredit, "requestCredit, credit");

        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "requestCredit, multistrategy balance");

        uint256 actualStrategyBalance = dai.balanceOf(address(strategy));
        uint256 expectedStrategyBalance = 500 ether;
        assertEq(actualStrategyBalance, expectedStrategyBalance, "requestCredit, strategy balance");
    }
}