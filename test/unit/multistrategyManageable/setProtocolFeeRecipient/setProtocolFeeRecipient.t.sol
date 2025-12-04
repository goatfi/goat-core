// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IMultistrategyManageable } from "src/interfaces/IMultistrategyManageable.sol";

contract SetProtocolFeeRecipient_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.setProtocolFeeRecipient(users.feeRecipient);
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.owner); 
        _;
    }

    function test_RevertWhen_ProtocolFeeRecipientIsZeroAddress() external whenCallerIsOwner {
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        multistrategy.setProtocolFeeRecipient(address(0));
    }

    modifier whenProtocolFeeRecipientIsNotZeroAddress() {
        _;
    }

    function test_SetProtocolFeeRecipient() 
        external 
        whenCallerIsOwner 
        whenProtocolFeeRecipientIsNotZeroAddress 
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.ProtocolFeeRecipientSet(users.feeRecipient);

        multistrategy.setProtocolFeeRecipient(users.feeRecipient);

        address actualProtocolFeeRecipient = multistrategy.protocolFeeRecipient();
        address expectedProtocolFeeRecipient = users.feeRecipient;
        assertEq(actualProtocolFeeRecipient, expectedProtocolFeeRecipient, "setProtocolFeeRecipient");
    }
}