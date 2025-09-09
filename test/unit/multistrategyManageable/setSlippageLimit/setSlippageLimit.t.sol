// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetSlippageLimit_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 newLimit;

    function test_RevertWhen_CallerNotManager() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.setSlippageLimit(5_000);
    }

    modifier whenCallerIsManager() {
        vm.prank(users.manager);
        _;
    }

    function test_RevertWhen_SlippageLimitAboveMaximum() external whenCallerIsManager {
        newLimit = 10_001; // Above MAX_BPS (10_000)
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageLimitExceeded.selector, newLimit));
        multistrategy.setSlippageLimit(newLimit);
    }

    modifier whenSlippageLimitWithinAllowedRange() {
        newLimit = 7_500;
        _;
    }

    function test_SetSlippageLimit_ViaManager() 
        external 
        whenCallerIsManager 
        whenSlippageLimitWithinAllowedRange 
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.SlippageLimitSet(newLimit);

        multistrategy.setSlippageLimit(newLimit);

        uint256 actualSlippageLimit = multistrategy.slippageLimit();
        uint256 expectedSlippageLimit = newLimit;
        assertEq(actualSlippageLimit, expectedSlippageLimit, "setSlippageLimit");
    }

    modifier whenCallerIsOwner() {
        vm.prank(users.owner);
        _;
    }

    function test_SetSlippageLimit_ViaOwner() 
        external 
        whenCallerIsOwner 
        whenSlippageLimitWithinAllowedRange  
    {
        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.SlippageLimitSet(newLimit);

        multistrategy.setSlippageLimit(newLimit);

        uint256 actualSlippageLimit = multistrategy.slippageLimit();
        uint256 expectedSlippageLimit = newLimit;
        assertEq(actualSlippageLimit, expectedSlippageLimit, "setSlippageLimit by owner");
    }
}