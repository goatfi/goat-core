// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IMultistrategyManageable } from "src/interfaces/IMultistrategyManageable.sol";

contract SetPerformanceFee_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint16 newFee;

    function test_RevertWhen_CallerNotOwner() external {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.setPerformanceFee(1000);
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.owner); 
        _;
    }

    function test_RevertWhen_PerformanceFeeAboveMaximum() external whenCallerIsOwner {
        newFee = 2_001; // Above MAX_PERFORMANCE_FEE (2_000)
        vm.expectRevert(abi.encodeWithSelector(Errors.ExcessiveFee.selector, newFee));
        multistrategy.setPerformanceFee(newFee);
    }

    modifier whenPerformanceFeeWithinAllowedRange() {
        newFee = 1_500;
        _;
    }

    function test_SetPerformanceFee() 
        external 
        whenCallerIsOwner 
        whenPerformanceFeeWithinAllowedRange 
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.PerformanceFeeSet(newFee);

        multistrategy.setPerformanceFee(newFee);

        uint256 actualPerformanceFee = multistrategy.performanceFee();
        uint256 expectedPerformanceFee = newFee;
        assertEq(actualPerformanceFee, expectedPerformanceFee, "setPerformanceFee");
    }
}