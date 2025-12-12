// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";

contract Unpause_Integration_Concrete_Test is Adapter_Base_Test {
    event Unpaused(address account);

    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.unpause();
    }

    modifier whenCallerOwner() {
        _;
    }

    function test_RevertWhen_ContractNotPaused()
        external
        whenCallerOwner
    {
        vm.expectRevert(abi.encodeWithSelector(Pausable.ExpectedPause.selector));
        vm.prank(users.manager); strategy.unpause();
    }

    modifier whenContractPaused() {
        vm.prank(users.guardian); strategy.pause();
        _;
    }

    function test_Unpause()
        external
        whenCallerOwner
        whenContractPaused
    {
        // Expect the relevant event to be emitted
        vm.expectEmit({emitter: address(strategy)});
        emit Unpaused(users.manager);
        
        vm.prank(users.manager); strategy.unpause();

        // Assert contract is not paused
        bool actualStrategyPaused = strategy.paused();
        bool expectedStrategyPaused = false;
        assertEq(actualStrategyPaused, expectedStrategyPaused, "pause");

        // Assert contract allowances are set
        uint256 actualAssetAllowances = IERC20(strategy.asset()).allowance(address(strategy), address(strategy.vault()));
        uint256 expectedAssetAllowance = type(uint256).max;
        assertEq(actualAssetAllowances, expectedAssetAllowance, "unpause");
    }
}