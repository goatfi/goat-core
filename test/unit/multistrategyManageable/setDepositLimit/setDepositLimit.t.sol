// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetDepositLimit_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_RevertWhen_CallerNotManager() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotManager.selector, users.bob));
        vm.prank(users.bob); multistrategy.setDepositLimit(100_000 ether);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_SetDepositLimit() external whenCallerIsManager {
        uint256 newLimit = 200_000 ether;

        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.DepositLimitSet(newLimit);

        // Set the deposit limit
        vm.prank(users.manager); multistrategy.setDepositLimit(newLimit);

        // Assert the deposit limit has been set
        uint256 actualDepositLimit = multistrategy.depositLimit();
        uint256 expectedDepositLimit = newLimit;
        assertEq(actualDepositLimit, expectedDepositLimit, "setDepositLimit");
    }
}