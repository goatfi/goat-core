// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;


import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Pausable } from "@openzeppelin/utils/Pausable.sol";
import { Errors } from "src/libraries/Errors.sol";

interface IPausable {
    event Unpaused(address account);

    function paused() external view returns (bool);
}

contract Unpause_Integration_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotOwner() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.unpause();
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.owner);
        _;
    }

    function test_RevertWhen_ContractIsUnpaused() 
        external 
        whenCallerIsOwner 
    {
        // Expect a revert.
        vm.expectRevert(abi.encodeWithSelector(Pausable.ExpectedPause.selector));
        multistrategy.unpause();
    }

    modifier whenContractIsPaused() {
        multistrategy.pause();
        _;
    }

    function test_Unpause_PausedContract() 
        external 
        whenCallerIsOwner 
        whenContractIsPaused 
    {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IPausable.Unpaused({ account: users.owner });

        // Pause the contract.
        vm.prank(users.owner); multistrategy.unpause();

        // Assert that the contract has been paused.
        bool isPaused = IPausable(address(multistrategy)).paused();
        bool expectedToBePaused = false;
        assertEq(isPaused, expectedToBePaused, "unpause");
    }
}