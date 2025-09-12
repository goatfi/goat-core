// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { StrategyAdapterAdminable } from "./StrategyAdapterAdminable.sol";
import { IStrategyAdapter } from "interfaces/IStrategyAdapter.sol";
import { IMultistrategy } from "interfaces/IMultistrategy.sol";
import { Errors } from "../libraries/Errors.sol";

abstract contract StrategyAdapter is IStrategyAdapter, StrategyAdapterAdminable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @dev 100% in BPS, setting the slippage to 100% means no slippage protection.
    uint256 constant MAX_SLIPPAGE = 10_000;

    /// @inheritdoc IStrategyAdapter
    address public immutable multistrategy;

    /// @inheritdoc IStrategyAdapter
    address public immutable asset;

    /// @inheritdoc IStrategyAdapter
    uint256 public slippageLimit;

    /// @notice Name of this Strategy Adapter
    string public name;

    /// @notice Identifier of this Strategy Adapter
    string public id;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/
    
    /// @dev Reverts if `_asset` doesn't match `asset` on the Multistrategy.
    /// @param _multistrategy Address of the multistrategy this strategy will belongs to.
    constructor(address _multistrategy, string memory _name, string memory _id) StrategyAdapterAdminable(msg.sender) {
        multistrategy = _multistrategy;
        asset = IERC4626(_multistrategy).asset();
        name = _name;
        id = _id;

        IERC20(asset).forceApprove(multistrategy, type(uint256).max);
    }

    /// @dev Reverts if called by any account other than the Multistrategy this strategy belongs to.
    modifier onlyMultistrategy() {
        require(msg.sender == multistrategy, Errors.CallerNotMultistrategy(msg.sender));
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStrategyAdapter
    function totalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    /// @inheritdoc IStrategyAdapter
    function currentPnL() external view returns (uint256, uint256) {
        return _calculateGainAndLoss(_totalAssets());
    }

    /// @inheritdoc IStrategyAdapter
    function availableLiquidity() external view returns (uint256) {
        return _availableLiquidity();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IStrategyAdapter
    function requestCredit() external onlyOwner whenNotPaused returns (uint256 creditRequested) {
        creditRequested = IMultistrategy(multistrategy).requestCredit();
        if(creditRequested > 0) {
            _deposit();
        }
    }

    /// @inheritdoc IStrategyAdapter
    function setSlippageLimit(uint256 _slippageLimit) external onlyOwner {
        require(_slippageLimit <= MAX_SLIPPAGE, Errors.SlippageLimitExceeded(_slippageLimit));
        
        slippageLimit = _slippageLimit;

        emit SlippageLimitSet(_slippageLimit);
    }
    
    /// @inheritdoc IStrategyAdapter
    function sendReport(uint256 _repayAmount) external onlyOwner whenNotPaused {
        _sendReport(_repayAmount);
    }

    /// @inheritdoc IStrategyAdapter
    function askReport() external onlyMultistrategy whenNotPaused {
        _sendReport(0);
    }

    /// @inheritdoc IStrategyAdapter
    function sendReportPanicked() external onlyOwner whenPaused {
        uint256 currentAssets = _balance();
        (uint256 gain, uint256 loss) = _calculateGainAndLoss(currentAssets);
        uint256 availableForRepay = currentAssets - gain;
        IMultistrategy(multistrategy).strategyReport(availableForRepay, gain, loss);
    }

    /// @inheritdoc IStrategyAdapter
    /// @dev Any surplus on the withdraw won't be sent to the multistrategy.
    /// It will be eventually reported back as gain when sendReport is called.
    function withdraw(uint256 _amount) external onlyMultistrategy whenNotPaused returns (uint256 withdrawn) {
        _tryWithdraw(_amount);
        withdrawn = Math.min(_amount, _balance());
        IERC20(asset).safeTransfer(multistrategy, withdrawn);
    }

    /// @inheritdoc IStrategyAdapter
    function panic() external onlyGuardian {
        _emergencyWithdraw();
        _revokeAllowances();
        _pause();
    }

    /// @inheritdoc IStrategyAdapter
    function pause() external onlyGuardian {
        _revokeAllowances();
        _pause();
    }

    /// @inheritdoc IStrategyAdapter
    function unpause() external onlyOwner {
        _unpause();
        _giveAllowances();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the gain and loss based on current assets.
    /// @param _currentAssets The current assets held by the strategy.
    /// @return gain The calculated gain.
    /// @return loss The calculated loss.
    function _calculateGainAndLoss(uint256 _currentAssets) internal view returns (uint256 gain, uint256 loss) {
        uint256 totalDebt = IMultistrategy(multistrategy).strategyTotalDebt(address(this));
        if(_currentAssets >= totalDebt) {
            gain = _currentAssets - totalDebt;
        } else {
            loss = totalDebt - _currentAssets;
        }
    }

    /// @notice Returns the current balance of asset in this contract.
    function _balance() internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    /// @notice Returns the amount of `asset` the underlying strategy holds. 
    /// @dev In the case this strategy has swapped `asset` for another asset, it should return the most approximate value.
    /// Child contract must implement the logic to calculate the amount of assets.
    function _totalAssets() internal virtual view returns (uint256);

    /// @notice Returns the available liquidity of this adapter.
    /// @dev Child contract must implement the logic to calculate the available liquidity.
    function _availableLiquidity() internal view virtual returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sends a report on the strategy's performance.
    /// @param _repayAmount The amount to be repaid to the multi-strategy.
    function _sendReport(uint256 _repayAmount) internal {
        (uint256 gain, uint256 loss) = _calculateGainAndLoss(_totalAssets());
        uint256 exceedingDebt = IMultistrategy(multistrategy).debtExcess(address(this));
        uint256 repayCap = Math.min(_repayAmount, exceedingDebt);
        uint256 toBeWithdrawn = Math.min(repayCap + gain, _totalAssets());

        _tryWithdraw(toBeWithdrawn);
        (gain, loss) = _calculateGainAndLoss(_totalAssets());
        uint256 currentBalance = _balance();
        if(currentBalance > gain) {
            IMultistrategy(multistrategy).strategyReport(currentBalance - gain, gain, loss);
        } else {
            IMultistrategy(multistrategy).strategyReport(0, currentBalance, loss);
        }
    }

    /// @notice Attempts to withdraw a specified amount from the strategy.
    /// @param _amount The amount to withdraw from the strategy.
    function _tryWithdraw(uint256 _amount) internal {
        if(_amount == 0 || _amount <= _balance()) return;

        // Balance is considered as amount already withdrawn, this amount doesn't need to be withdrawn.
        _withdraw(_amount - _balance());

        uint256 currentBalance = _balance();
        uint256 desiredBalance = _amount.mulDiv(MAX_SLIPPAGE - slippageLimit, MAX_SLIPPAGE);
        
        require(currentBalance >= desiredBalance, Errors.SlippageCheckFailed(desiredBalance, currentBalance));
    }

    /// @notice Deposits the entire balance of `asset` this contract holds into the underlying strategy. 
    /// @dev Child contract must implement the logic that will put the funds to work.
    function _deposit() internal virtual;

    /// @notice Withdraws the specified `_amount` of `asset` from the underlying strategy. 
    /// @dev Child contract must implement the logic that will withdraw the funds.
    /// @param _amount The amount of `asset` to withdraw.
    function _withdraw(uint256 _amount) internal virtual;

    /// @notice Withdraws as much funds as possible from the underlying strategy.
    /// @dev Child contract must implement the logic to withdraw as much funds as possible.
    /// The withdraw process shouldn't have a slippage check, as it is in an emergency situation.
    function _emergencyWithdraw() internal virtual;

    /// @dev Grants allowance for `asset` to the contracts used by the strategy adapter.
    /// It should be overridden by derived contracts to specify the exact contracts and amounts for the allowances.
    function _giveAllowances() internal virtual;

    /// @dev Revokes all previously granted allowances for `asset`.
    /// It should be overridden by derived contracts to specify the exact contracts from which allowances are revoked.
    function _revokeAllowances() internal virtual;
}