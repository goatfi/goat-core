// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract SetSlippageLimit_Integration_Concrete_Test is Multistrategy_Base_Test {

    function test_RevertWhen_CallerNotManager() external {
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotManager.selector, users.bob));
        vm.prank(users.bob); multistrategy.setSlippageLimit(5_000);
    }

    modifier whenCallerIsManager() {
        _;
    }

    function test_RevertWhen_SlippageLimitAboveMaximum() external whenCallerIsManager {
        uint256 excessiveLimit = 10_001; // Above MAX_BPS (10_000)
        // Expect a revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageLimitExceeded.selector, excessiveLimit));
        vm.prank(users.manager); multistrategy.setSlippageLimit(excessiveLimit);
    }

    modifier whenSlippageLimitWithinAllowedRange() {
        _;
    }

    function test_SetSlippageLimit() external whenCallerIsManager whenSlippageLimitWithinAllowedRange {
        uint256 newLimit = 7_500;

        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.SlippageLimitSet(newLimit);

        // Set the slippage limit
        vm.prank(users.manager); multistrategy.setSlippageLimit(newLimit);

        // Assert the slippage limit has been set
        uint256 actualSlippageLimit = multistrategy.slippageLimit();
        uint256 expectedSlippageLimit = newLimit;
        assertEq(actualSlippageLimit, expectedSlippageLimit, "setSlippageLimit");
    }
}