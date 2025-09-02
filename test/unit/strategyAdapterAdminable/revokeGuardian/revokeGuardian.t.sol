// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

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
        vm.startPrank(users.manager);
        _;
        vm.stopPrank();
    }

    function test_RevokeGuardian_Success() external whenCallerIsOwner {
        address guardian = users.guardian;

        // Enable the guardian first
        strategy.enableGuardian(guardian);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit IStrategyAdapterAdminable.GuardianRevoked(guardian);

        strategy.revokeGuardian(guardian);

        assertFalse(strategy.guardians(guardian));
    }
}