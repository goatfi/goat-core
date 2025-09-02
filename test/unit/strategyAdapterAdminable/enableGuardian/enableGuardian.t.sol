// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IStrategyAdapterAdminable } from "src/interfaces/IStrategyAdapterAdminable.sol";

contract EnableGuardian_Test is StrategyAdapter_Base_Test {

    function test_EnableGuardian_RevertWhenNotOwner() external {
        address guardian = users.guardian;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.startPrank(users.bob); strategy.enableGuardian(guardian);
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.manager);
        _;
    }

    function test_EnableGuardian_Success() external whenCallerIsOwner {
        address guardian = users.guardian;

        vm.expectEmit(true, true, true, true, address(strategy));
        emit IStrategyAdapterAdminable.GuardianEnabled(guardian);

        strategy.enableGuardian(guardian);

        assertTrue(strategy.guardians(guardian));
    }
}