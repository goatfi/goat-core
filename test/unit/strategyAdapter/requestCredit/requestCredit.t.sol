// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";

contract RequestCredit_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.requestCredit();
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevertWhen_ContractIsPaused()
        external
        whenCallerIsOwner
    {
        vm.prank(users.guardian); strategy.pause();
        
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.manager); strategy.requestCredit();
    }

    modifier whenNotPaused() {
        _;
    }

    function test_RequestCredit_NoCredit()
        external
        whenCallerIsOwner
        whenNotPaused
    {
        uint256 previousTotalAssets = strategy.totalAssets();

        vm.prank(users.manager); uint256 actualCredit = strategy.requestCredit();

        // Assert credit is 0
        uint256 expectedCredit = 0;
        assertEq(actualCredit, expectedCredit, "requestCredit, credit amount");

        // Assert totalAssets didn't increase
        uint256 actualTotalAssets = strategy.totalAssets();
        uint256 expectedTotalAssets = previousTotalAssets;
        assertEq(actualTotalAssets, expectedTotalAssets, "requestCredit, totalAssets");
    }

    function test_RequestCredit()
        external
        whenCallerIsOwner
        whenNotPaused
    {   
        uint256 amount = 1_000 ether;
        _userDeposit(users.bob,amount);
        
        vm.prank(users.manager); uint256 actualCredit = strategy.requestCredit();

        // Assert the size of the credit
        uint256 expectedCredit = amount;
        assertEq(actualCredit, expectedCredit, "requestCredit, credit amount");

        // Assert totalAssets has increased
        uint256 actualTotalAssets = strategy.totalAssets();
        uint256 expectedTotalAssets = amount;
        assertEq(actualTotalAssets, expectedTotalAssets, "requestCredit, totalAssets");

        // Assert the credit has been deposited into the underlying strategy
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = amount;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "requestCredit, strategy assets");
    }
}