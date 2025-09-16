// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { IMultistrategy } from "interfaces/IMultistrategy.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract RequestCredit_Integration_Concrete_Test is Multistrategy_Base_Test {
    MockStrategyAdapter strategy;

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
        strategy = _createAndAddAdapter(0, 0 , type(uint256).max);
        _userDeposit(users.bob, 1_000 ether);
        _;
    }

    function test_RequestCredit_NoAvailableCredit()
        external
        whenContractNotPaused
        whenCallerActiveStrategy
    {   
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
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(strategy), 5_000);

        vm.expectEmit({emitter: address(multistrategy)});
        emit IMultistrategy.CreditRequested(address(strategy), 500 ether);
        vm.prank(address(strategy)); uint256 actualCredit = multistrategy.requestCredit();

        uint256 actualMultistrategyTotalDebt = multistrategy.totalDebt();
        uint256 expectedMultistrategyTotalDebt = 500 ether;
        assertEq(actualMultistrategyTotalDebt, expectedMultistrategyTotalDebt, "requestCredit, multistrategy totalDebt");

        uint256 actualStrategyDebt = multistrategy.strategyTotalDebt(address(strategy));
        uint256 expectedStrategyDebt = 500 ether;
        assertEq(actualStrategyDebt, expectedStrategyDebt, "requestCredit, strategy debt");

        uint256 actualMultistrategyBalance = dai.balanceOf(address(multistrategy));
        uint256 expectedMultistrategyBalance = 500 ether;
        assertEq(actualMultistrategyBalance, expectedMultistrategyBalance, "requestCredit, multistrategy balance");

        uint256 actualStrategyBalance = dai.balanceOf(address(strategy));
        uint256 expectedStrategyBalance = 500 ether;
        assertEq(actualStrategyBalance, expectedStrategyBalance, "requestCredit, strategy balance");

        uint256 expectedCredit = 500 ether;
        assertEq(actualCredit, expectedCredit, "requestCredit, credit");
    }
}