// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @notice Namespace for the structs used in `Multistrategy`
library DataTypes {
    /// @notice Struct that contains a strategy data
    /// @param queueIndex Index of this strategy in WithdrawQueue.
    /// @param lastReport Timestamp of this strategy last report.
    /// @param debtRatio Maximum amount the strategy can borrow from the Multistrategy (in BPS of total assets in a Multistrategy)
    /// @param minDebtDelta Lower limit on the increase or decrease of debt since last harvest
    /// @param maxDebtDelta Upper limit on the increase or decrease of debt since last harvest
    /// @param totalDebt Total debt that this strategy has
    /// @param totalGain Total gains that this strategy has realized
    /// @param totalLoss Total losses that this strategy has realized
    struct StrategyParams {
        uint8 queueIndex;   // 1 byte  - slot 0
        uint32 lastReport;     // 4 bytes - slot 0
        uint256 debtRatio;
        uint256 minDebtDelta;
        uint256 maxDebtDelta;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalLoss;
    }
}