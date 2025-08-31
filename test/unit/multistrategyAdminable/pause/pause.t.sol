// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

interface IPausable {
    event Paused(address account);

    function paused() external view returns (bool);
}

contract Pause_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_RevertWhen_CallerNotGuardian() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGuardian.selector, users.bob));
        vm.prank(users.bob); multistrategy.pause();
    }

    modifier whenCallerIsGuardian() {
        vm.prank(users.guardian);
        _;
    }

    function test_RevertWhen_ContractIsPaused() external whenCallerIsGuardian {
        // Pause the contract so we can test the revert.
        multistrategy.pause();

        // Expect a revert.
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vm.prank(users.owner); multistrategy.pause();
    }

    modifier whenContractIsUnpaused() {
        _;
    }

    function test_Pause_UnpausedContract() external whenCallerIsGuardian whenContractIsUnpaused {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IPausable.Paused({ account: users.guardian });

        // Pause the contract.
        multistrategy.pause();

        // Assert that the contract has been paused.
        bool isPaused = IPausable(address(multistrategy)).paused();
        bool expectedToBePaused = true;
        assertEq(isPaused, expectedToBePaused, "pause");
    }
}