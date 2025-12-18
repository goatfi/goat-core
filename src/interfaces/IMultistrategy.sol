// SPDX-License-Identifier: GNU AGPLv3

pragma solidity ^0.8.27;

import { IMultistrategyManageable } from "./IMultistrategyManageable.sol";

interface IMultistrategy is IMultistrategyManageable {
    /// @notice Emitted when a strategy has requested a credit.
    /// @param strategy Address of the strategy that requested the credit.
    /// @param amount Amount of credit that has been granted to the strategy.
    event CreditRequested(address indexed strategy, uint256 amount);

    /// @notice Emitted when a strategy has submitted a report.
    /// @param strategy Address of the strategy that has submitted the report.
    /// @param debtRepaid Amount of debt that has been repaid by the strategy.
    /// @param gain Amount of gain that the strategy has reported.
    /// @param loss Amount of loss that the strategy has reported.
    event StrategyReported(address indexed strategy, uint256 debtRepaid, uint256 gain, uint256 loss);

    /// @notice Timestamp of the last report made by a strategy.
    function lastReport() external view returns (uint256);

    /// @notice Amount of tokens that are locked as "locked profit" and can't be withdrawn.
    function lockedProfit() external view returns (uint256);

    /// @notice Returns the amount of tokens a strategy can borrow from this Multistrategy.
    /// @param strategy Address of the strategy we want to know the credit available for.
    function creditAvailable(address strategy) external view returns (uint256);

    /// @notice Returns the excess of debt a strategy currently holds.
    /// @param strategy Address of the strategy we want to know if it has any debt excess.
    function debtExcess(address strategy) external view returns (uint256);

    /// @notice Returns the total debt of `strategy`.
    /// @param strategy Address of the strategy we want to know the `totalDebt`.
    function strategyTotalDebt(address strategy) external view returns (uint256);

    /// @notice Returns the aggregate PnL of all strategies at max slippage.
    /// @return gain The aggregate gain.
    /// @return loss The aggregate loss.
    function currentPnL() external view returns (uint256, uint256);

    /// @notice Returns the current available liqudity of this Multistrategy.
    function availableLiquidity() external view returns (uint256);
    
    /// @notice Send the available credit of the caller to the caller.
    /// @dev Reverts if the caller is *NOT* an active strategy
    /// @return The amount sent to the caller.
    function requestCredit() external returns (uint256);

    /// @notice Report the profit or loss of a strategy along any debt the strategy is willing to pay back.
    /// @dev Can only be called by an active strategy.
    /// @param _debtRepayment Amount that the strategy will send back to the multistrategy as debt repayment.
    /// @param _gain Amount that the strategy has realized as a gain since the last report and will send it to this Multistrategy as earnings. 
    /// @param _loss Amount that the strategy has realized as a loss since the last report. 
    function strategyReport(uint256 _debtRepayment, uint256 _gain, uint256 _loss) external;

    /// @notice Rescue any token that is not the Multistrategy's asset.
    /// @dev Can only be called by a guardian.
    /// @param token Address of the token to rescue.
    function rescueToken(address token) external;
}