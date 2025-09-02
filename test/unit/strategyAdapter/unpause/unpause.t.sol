// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { IStrategyAdapterAdminable } from "interfaces/IStrategyAdapterAdminable.sol";
import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";

contract Unpause_Integration_Concrete_Test is StrategyAdapter_Base_Test {
    event Unpaused(address account);

    function test_RevertWhen_CallerNotOwner() external {
        // Expect a revert
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
        // Expect a revert
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
        address stakingContract = address(strategy.vault());
        uint256 actualAssetAllowances = IERC20(strategy.asset()).allowance(address(strategy), stakingContract);
        uint256 expectedAssetAllowance = type(uint256).max;
        assertEq(actualAssetAllowances, expectedAssetAllowance, "unpause");
    }
}