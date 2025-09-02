// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetProtocolFeeRecipient_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_RevertWhen_CallerNotOwner() external {
        // Expect a revert with Ownable error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.setProtocolFeeRecipient(users.feeRecipient);
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevertWhen_ProtocolFeeRecipientIsZeroAddress() external whenCallerIsOwner {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        vm.prank(users.owner); multistrategy.setProtocolFeeRecipient(address(0));
    }

    modifier whenProtocolFeeRecipientIsNotZeroAddress() {
        _;
    }

    function test_SetProtocolFeeRecipient() external whenCallerIsOwner whenProtocolFeeRecipientIsNotZeroAddress {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.ProtocolFeeRecipientSet(users.feeRecipient);

        // Set the protocol fee recipient
        vm.prank(users.owner); multistrategy.setProtocolFeeRecipient(users.feeRecipient);

        // Assert the protocol fee recipient has been set
        address actualProtocolFeeRecipient = multistrategy.protocolFeeRecipient();
        address expectedProtocolFeeRecipient = users.feeRecipient;
        assertEq(actualProtocolFeeRecipient, expectedProtocolFeeRecipient, "setProtocolFeeRecipient");
    }
}