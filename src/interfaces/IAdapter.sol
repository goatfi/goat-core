// SPDX-License-Identifier: GNU AGPLv3

pragma solidity ^0.8.27;

interface IAdapter {
    /// @notice Emitted when the slippage limit is set.
    /// @param slippageLimit The new slippage limit in basis points (BPS).
    event SlippageLimitSet(uint256 slippageLimit);

    /// @notice Returns the address of the multistrategy this Strategy belongs to.
    function multistrategy() external view returns (address);

    /// @notice Returns the address of the token used by this strategy.
    function asset() external view returns (address);

    /// @notice Returns the identifier of this Strategy Adapter.
    function id() external view returns (string memory);

    /// @notice Returns the name of this Strategy Adapter.
    function name() external view returns (string memory);

    /// @notice Returns the current slippage limit in basis points (BPS).
    /// @dev The slippage limit is expressed in BPS, where 10,000 BPS equals 100%.
    function slippageLimit() external view returns (uint256);

    /// @notice Sets the maximum allowable slippage limit for withdrawals.
    /// @dev Slippage limit is expressed in basis points (BPS), where 10,000 BPS equals 100%.
    /// This limit represents the tolerated difference between the expected withdrawal amount
    /// and the actual amount withdrawn from the strategy.
    /// @param _slippageLimit The maximum allowable slippage in basis points.
    function setSlippageLimit(uint256 _slippageLimit) external;

    /// @notice Requests a credit to the multistrategy. The multistrategy will send the
    /// maximum amount of credit available for this strategy.
    /// @return The amount of credit received.
    function requestCredit() external returns(uint256);

    /// @notice Sends a report to the Multistrategy of any gain or loss this strategy has
    ///         made along an amount to be withdrawn and be used for debt repayment.
    /// @dev Only the owner can call it
    /// @param _amountToWithdraw Amount that will be withdrawn from the strategy and will
    ///         be available for debt repayment.
    function sendReport(uint256 _amountToWithdraw) external;

    /// @notice Sends a report to the Multistrategy of any gain or loss this strategy has made.
    /// @dev This report wont withdraw any funds to repay debt to the Multistrategy.
    /// Only the multistrategy can call it
    function askReport() external;

    /// @notice Withdraws `asset` from the strategy.
    /// @dev Only callable by the multistrategy.
    /// @param _amount Amount of tokens to withdraw from the strategy.
    /// @return The amount withdrawn.
    function withdraw(uint256 _amount) external returns (uint256);

    /// @notice Returns the amount of `asset` this strategy holds.
    function totalAssets() external view returns (uint256);

    /// @notice Returns the gain and loss this strategy has made since the last report.
    /// @dev The returned values will account for max slippage.
    /// @return gain The gain amount.
    /// @return loss The loss amount.
    function currentPnL() external view returns (uint256, uint256);

    /// @notice Returns the amount of liquidity currently available for withdrawals.
    /// @dev This represents the funds that can be withdrawn without affecting the adapter’s operations.
    function availableLiquidity() external view returns (uint256);

    /// @notice Starts the panic process for this strategy.
    /// @dev The panic process consists of:
    ///     - Withdraw as much funds as possible from the underlying strategy.
    ///     - Report back to the multistrategy with the available funds.
    ///     - Revoke the allowance that this adapter has given to the underlying strategy.
    ///     - Pauses this contract.
    function panic() external;
}