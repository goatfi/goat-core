// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetPerformanceFee_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_RevertWhen_CallerNotOwner() external {
        // Expect a revert with Ownable error
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.setPerformanceFee(1000);
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevertWhen_PerformanceFeeAboveMaximum() external whenCallerIsOwner {
        uint256 excessiveFee = 2_001; // Above MAX_PERFORMANCE_FEE (2_000)
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ExcessiveFee.selector, excessiveFee));
        vm.prank(users.owner); multistrategy.setPerformanceFee(excessiveFee);
    }

    modifier whenPerformanceFeeWithinAllowedRange() {
        _;
    }

    function test_SetPerformanceFee() external whenCallerIsOwner whenPerformanceFeeWithinAllowedRange {
        uint256 newFee = 1_500;

        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.PerformanceFeeSet(newFee);

        // Set the performance fee
        vm.prank(users.owner); multistrategy.setPerformanceFee(newFee);

        // Assert the performance fee has been set
        uint256 actualPerformanceFee = multistrategy.performanceFee();
        uint256 expectedPerformanceFee = newFee;
        assertEq(actualPerformanceFee, expectedPerformanceFee, "setPerformanceFee");
    }
}