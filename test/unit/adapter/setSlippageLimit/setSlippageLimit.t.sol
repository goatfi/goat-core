// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import { Adapter_Base_Test } from "../../../shared/Adapter_Base.t.sol";
import { IAdapter } from "src/interfaces/IAdapter.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Errors } from "src/libraries/Errors.sol";

contract SetSlippageLimit_Integration_Concrete_Test is Adapter_Base_Test {
    uint256 slippageLimit;

    function test_RevertWhen_CallerNotOwner() external {
        // Set the slippage limit to 1%
        slippageLimit = 100;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); strategy.setSlippageLimit(slippageLimit);
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevertWhen_SlippageLimitGreaterThanMaxSlippage()
        external
        whenCallerIsOwner
    {   
        // Set the slippage limit to 200%
        slippageLimit = 20_000;
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageLimitExceeded.selector, slippageLimit));
        vm.prank(users.manager); strategy.setSlippageLimit(slippageLimit);
    }

    modifier whenSlippageLimitIsLowerThanMaxSlippage() {
        slippageLimit = 10;
        _;
    }

    function test_SetSlippageLimit_LowerThan_MaxSlippage() 
        external
        whenCallerIsOwner
        whenSlippageLimitIsLowerThanMaxSlippage
    {
        vm.expectEmit({emitter: address(strategy)});
        emit IAdapter.SlippageLimitSet(slippageLimit);
        
        vm.prank(users.manager); strategy.setSlippageLimit(slippageLimit);

        uint256 actualSlippageLimit = strategy.slippageLimit();
        uint256 expectedSlippageLimit = slippageLimit;
        assertEq(actualSlippageLimit, expectedSlippageLimit, "setSlippageLimit, different amount");
    }

    modifier whenSlippageLimitEqualToMaxSlippage {
        slippageLimit = 10_000;
        _;
    }

    function test_SetSlippageLimit_EqualTo_MaxSlippage() 
        external
        whenCallerIsOwner
        whenSlippageLimitEqualToMaxSlippage
    {
        vm.expectEmit({emitter: address(strategy)});
        emit IAdapter.SlippageLimitSet(slippageLimit);
        
        vm.prank(users.manager); strategy.setSlippageLimit(slippageLimit);

        uint256 actualSlippageLimit = strategy.slippageLimit();
        uint256 expectedSlippageLimit = slippageLimit;
        assertEq(actualSlippageLimit, expectedSlippageLimit, "setSlippageLimit, different amount");
    }
}