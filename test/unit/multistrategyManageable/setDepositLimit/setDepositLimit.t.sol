// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "src/interfaces/IMultistrategyManageable.sol";

contract SetDepositLimit_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 newLimit = 200_000 ether;

    function test_RevertWhen_CallerNotManager() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.setDepositLimit(100_000 ether);
    }

    modifier whenCallerIsManager() {
        vm.prank(users.manager);
        _;
    }

    function test_SetDepositLimit_ViaManager() external whenCallerIsManager {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.DepositLimitSet(newLimit);

        multistrategy.setDepositLimit(newLimit);

        uint256 actualDepositLimit = multistrategy.depositLimit();
        uint256 expectedDepositLimit = newLimit;
        assertEq(actualDepositLimit, expectedDepositLimit, "setDepositLimit");
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.owner);
        _;
    }

    function test_SetDepositLimit_ViaOwner() external whenCallerIsOwner {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.DepositLimitSet(newLimit);

        multistrategy.setDepositLimit(newLimit);

        uint256 actualDepositLimit = multistrategy.depositLimit();
        uint256 expectedDepositLimit = newLimit;
        assertEq(actualDepositLimit, expectedDepositLimit, "setDepositLimit");
    }
}