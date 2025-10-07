// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Utils {
    function withdrawOrderIsValid(address[] memory withdrawOrder) external pure returns (bool) {
        bool seenZero = false;
        for (uint256 i = 0; i < withdrawOrder.length; i++) {
            if (withdrawOrder[i] == address(0)) {
                seenZero = true;
            } else if (seenZero) {
                return false;
            }
        }
        return true;
    }

    function nonZeroStrategies(address[] memory withdrawOrder) external pure returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < withdrawOrder.length; i++) {
            if (withdrawOrder[i] != address(0)) {
                count++;
            }
        }
        return count;
    }
}
