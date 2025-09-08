// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IStrategyAdapterAdminable } from "src/interfaces/IStrategyAdapterAdminable.sol";

contract RevokeGuardian_Test is StrategyAdapter_Base_Test {

    function test_RevokeGuardian_RevertWhenNotOwner() external {
        address guardian = users.guardian;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.revokeGuardian(guardian);
    }
    
    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevokeGuardian_Success() external whenCallerIsOwner {
        // Enable the guardian first
        vm.prank(users.manager); strategy.enableGuardian(users.alice);
        assertEq(strategy.guardians(users.alice), true, "alice not enabled as guardian");

        vm.expectEmit(true, true, true, true, address(strategy));
        emit IStrategyAdapterAdminable.GuardianRevoked(users.alice);

        vm.prank(users.manager); strategy.revokeGuardian(users.alice);

        bool isEnabled = strategy.guardians(users.alice);
        bool expectedToBeEnabled = false;
        assertEq(isEnabled, expectedToBeEnabled, "revoke guardian");
    }
}