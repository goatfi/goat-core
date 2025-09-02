// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.20 <0.9.0;

import { StrategyAdapter_Base_Test } from "../../../shared/StrategyAdapter_Base.t.sol";

contract TotalAssets_Integration_Concrete_Test is StrategyAdapter_Base_Test {

    function test_totalAssets_ZeroAssets() external view {
        uint256 actualTotalAssets = strategy.totalAssets();
        uint256 expectedTotalAssets = 0;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets, no credit requested");
    }

    modifier whenCreditRequested() {
        _requestCredit(1000 ether);
        _;
    }

    function test_totalAssets() 
        external
        whenCreditRequested
    {
        uint256 actualTotalAssets = strategy.totalAssets();
        uint256 expectedTotalAssets = 1000 ether;
        assertEq(actualTotalAssets, expectedTotalAssets, "totalAssets, credit requested");
    }
}