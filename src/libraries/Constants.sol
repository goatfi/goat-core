// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

/// @title Constants
/// @notice Library containing all constants used by the protocol.
library Constants {

    /// @notice Max Basis Points. 10_000 = 100%
    uint256 constant MAX_BPS = 10_000;

    /// @notice Max Performance fee in Basis Points. 2_000 = 20%
    uint256 constant MAX_PERFORMANCE_FEE = 2_000;

    /// @notice Max Slippage. 10_000 = 100%
    /// @dev Setting the slippage to 100% means no slippage protection.
    uint256 constant MAX_SLIPPAGE = 10_000;

    /// @notice How much time it takes for the profit of a strategy to be completely unlocked.
    uint256 constant PROFIT_UNLOCK_TIME = 3 days;

    /// @notice Max amount of different strategies the Multistrategy can manage.
    uint8 constant MAXIMUM_STRATEGIES = 10;
}