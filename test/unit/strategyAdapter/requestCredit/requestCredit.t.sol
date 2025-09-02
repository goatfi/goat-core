// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";

contract RequestCredit_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        // Expect it to revert
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
        
        // Expect it to revert
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

        vm.prank(users.manager); strategy.requestCredit();

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
        _userDeposit(users.bob, 1000 ether);
        
        vm.prank(users.manager); strategy.requestCredit();

        // Assert totalAssets has increased
        uint256 actualTotalAssets = strategy.totalAssets();
        uint256 expectedTotalAssets = 1000 ether;
        assertEq(actualTotalAssets, expectedTotalAssets, "requestCredit, totalAssets");

        // Assert the credit has been deposited into the underlying strategy
        uint256 actualStrategyAssets = strategy.totalAssets();
        uint256 expectedStrategyAssets = 1000 ether;
        assertEq(actualStrategyAssets, expectedStrategyAssets, "requestCredit, strategy assets");
    }
}