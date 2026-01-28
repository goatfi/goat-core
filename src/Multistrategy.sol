// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { IERC20, IERC4626, ERC20, ERC4626 } from "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import { ReentrancyGuard } from "@openzeppelin/utils/ReentrancyGuard.sol";
import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { MultistrategyManageable } from "./abstracts/MultistrategyManageable.sol";
import { IMultistrategy } from "./interfaces/IMultistrategy.sol";
import { IAdapter } from "./interfaces/IAdapter.sol";
import { Constants } from "./libraries/Constants.sol";
import { Errors } from "./libraries/Errors.sol";

contract Multistrategy is IMultistrategy, MultistrategyManageable, ERC4626, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using Math for uint256;

    /// @notice OpenZeppelin decimals offset used by the ERC4626 implementation.
    /// @dev Calculated to be max(0, 18 - underlyingDecimals) at construction, so the initial conversion rate maximizes
    /// precision between shares and assets.
    uint8 public immutable DECIMALS_OFFSET;

    /// @notice Determines the rate at which locked profit degrades over time.
    uint256 public immutable LOCKED_PROFIT_DEGRADATION;

    /// @inheritdoc IMultistrategy
    uint256 public lastReport;
    
    /// @inheritdoc IMultistrategy
    uint256 public lockedProfit;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Transfers ownership to the deployer of this contract
    /// @param _asset Address of the token used in this Multistrategy
    /// @param _owner Address of the initial Multistrategy owner
    /// @param _manager Address of the initial Multistrategy manager
    /// @param _protocolFeeRecipient Address that will receive the performance fees
    /// @param _name Name of this Multistrategy receipt token
    /// @param _symbol Symbol of this Multistrategy receipt token
    constructor(
        address _asset,
        address _owner,
        address _manager,
        address _protocolFeeRecipient,
        string memory _name,
        string memory _symbol
    ) 
        MultistrategyManageable(_owner, _manager, _protocolFeeRecipient)
        ERC4626(IERC20(_asset))
        ERC20(_name, _symbol)
    {   
        DECIMALS_OFFSET = (Math.max(0, 18 - IERC20Metadata(_asset).decimals())).toUint8();
        performanceFee = 1000;
        lastReport = block.timestamp;
        LOCKED_PROFIT_DEGRADATION = 1 ether / Constants.PROFIT_UNLOCK_TIME;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC4626
    function totalAssets() public view override returns (uint256) {
        return _balance() + totalDebt;
    }

    /// @inheritdoc IERC4626
    /// @dev Limited by the deposit limit
    function maxDeposit(address) public view override returns (uint256) {
        return totalAssets() >= depositLimit ? 0 : depositLimit - totalAssets();
    }

    /// @inheritdoc IERC4626
    /// @dev Limited by the deposit limit
    function maxMint(address _receiver) public view override returns (uint256) {
        return convertToShares(maxDeposit(_receiver));
    }

    /// @inheritdoc IERC4626
    /// @dev Limited by the liquidity available
    function maxWithdraw(address _owner) public view override returns (uint256) {
        uint256 maxAssets = previewRedeem(balanceOf(_owner));
        return Math.min(maxAssets, _availableLiquidity());
    }

    /// @inheritdoc IERC4626
    /// @dev Limited by the liquidity available
    function maxRedeem(address _owner) public view override returns (uint256) {
        uint256 maxShares = previewWithdraw(_availableLiquidity());
        return Math.min(balanceOf(_owner), maxShares);
    }

    /// @inheritdoc IERC4626
    /// @dev Pessimistic, returns the amount of shares at max slippage.
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        uint256 baseShares = _convertToShares(assets, Math.Rounding.Ceil);
        return baseShares.mulDiv(Constants.MAX_BPS, Constants.MAX_BPS - slippageLimit, Math.Rounding.Ceil);
    }

    /// @inheritdoc IERC4626
    /// @dev Pessimistic, returns the amount of assets at max slippage.
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        uint256 baseAssets = convertToAssets(shares);
        return baseAssets.mulDiv(Constants.MAX_BPS - slippageLimit, Constants.MAX_BPS, Math.Rounding.Floor);
    }

    /// @inheritdoc IMultistrategy
    function creditAvailable(address _strategy) external view returns (uint256) {
        return _creditAvailable(_strategy);
    }

    /// @inheritdoc IMultistrategy
    function debtExcess(address _strategy) external view returns (uint256) {
        return _debtExcess(_strategy);
    }

    /// @inheritdoc IMultistrategy
    function strategyTotalDebt(address _strategy) external view returns (uint256) {
        return strategies[_strategy].totalDebt;
    }

    /// @inheritdoc IMultistrategy
    function currentPnL() external view returns (uint256, uint256) {
        return _currentPnL();
    }

    /// @inheritdoc IMultistrategy
    function availableLiquidity() external view returns (uint256) {
        return _availableLiquidity();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC4626
    function deposit(uint256 _assets, address _receiver) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 maxAssets = maxDeposit(_receiver);
        require(_assets <= maxAssets, ERC4626ExceededMaxDeposit(_receiver, _assets, maxAssets));

        uint256 shares = previewDeposit(_assets);
        _enter(msg.sender, _receiver, _assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    function mint(uint256 _shares, address _receiver) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 maxShares = maxMint(_receiver);
        require(_shares <= maxShares, ERC4626ExceededMaxMint(_receiver, _shares, maxShares));

        uint256 assets = previewMint(_shares);
        _enter(msg.sender, _receiver, assets, _shares);

        return assets;
    }

    /// @inheritdoc IERC4626
    function withdraw(uint256 _assets, address _receiver, address _owner) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 maxAssets = maxWithdraw(_owner);
        require(_assets <= maxAssets, ERC4626ExceededMaxWithdraw(_owner, _assets, maxAssets));

        uint256 desiredShares = _convertToShares(_assets, Math.Rounding.Ceil);
        _settleUnrealizedLosses();
        uint256 shares = _convertToShares(_assets, Math.Rounding.Ceil);

        _checkSlippage(_assets, _assets, desiredShares, shares);
        _exit(msg.sender, _receiver, _owner, _assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 _shares, address _receiver, address _owner) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 maxShares = maxRedeem(_owner);
        require(_shares <= maxShares, ERC4626ExceededMaxRedeem(_owner, _shares, maxShares));

        uint256 desiredAssets = convertToAssets(_shares);
        _settleUnrealizedLosses();
        uint256 assets = convertToAssets(_shares);

        _checkSlippage(desiredAssets, assets, _shares, _shares);
        _exit(msg.sender, _receiver, _owner, assets, _shares);

        return assets;
    }

    /// @inheritdoc IMultistrategy
    function requestCredit() external whenNotPaused onlyActiveStrategy(msg.sender) returns (uint256) {
        return _requestCredit();
    }

    /// @inheritdoc IMultistrategy
    function strategyReport(uint256 _debtRepayment, uint256 _gain, uint256 _loss) 
        external 
        whenNotPaused
        onlyActiveStrategy(msg.sender)
    {
        _report(_debtRepayment, _gain, _loss);
    }
    
    /// @inheritdoc IMultistrategy
    function rescueToken(address _token) external onlyGuardian {
        require(_token != asset(), Errors.InvalidAddress(_token));

        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, balance);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal view function to retrieve the current asset balance of the contract.
    /// @return The current balance of the asset of the contract.
    function _balance() internal view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    /// @notice Converts a given amount of assets to shares, with specified rounding.
    /// @param _assets The amount of assets to convert to shares.
    /// @param rounding The rounding direction to apply during the conversion.
    /// @return The number of shares corresponding to the given amount of assets.
    function _convertToShares(uint256 _assets, Math.Rounding rounding) internal view override returns (uint256) {
        return _assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), _freeFunds() + 1, rounding);
    }

    /// @notice Convert a given amount of shares to assets, with specified rounding.
    /// @param _shares The number of shares to convert to assets.
    /// @param rounding The rounding direction to apply during the conversion.
    /// @return The amount of assets corresponding to the given number of shares.
    function _convertToAssets(uint256 _shares, Math.Rounding rounding) internal view override returns (uint256) {
        return _shares.mulDiv(_freeFunds() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /// @notice Calculates the available credit for a strategy.
    /// @param _strategy The address of the strategy for which to determine the available credit.
    /// @return The amount of credit available for the given strategy.
    function _creditAvailable(address _strategy) internal view returns (uint256) {
        uint256 mTotalAssets = totalAssets();
        uint256 mDebtLimit = debtRatio.mulDiv(mTotalAssets, Constants.MAX_BPS, Math.Rounding.Floor);

        uint256 sDebtLimit = strategies[_strategy].debtRatio.mulDiv(mTotalAssets, Constants.MAX_BPS, Math.Rounding.Floor);
        uint256 sTotalDebt = strategies[_strategy].totalDebt;

        if(sTotalDebt >= sDebtLimit || totalDebt >= mDebtLimit){
            return 0;
        }

        uint256 credit = sDebtLimit - sTotalDebt;
        uint256 maxAvailableCredit = mDebtLimit - totalDebt;
        credit = Math.min(credit, maxAvailableCredit);

        // Bound to the minimum and maximum borrow limits
        if(credit < strategies[_strategy].minDebtDelta) {
            return 0;
        } else {
            return Math.min(credit, strategies[_strategy].maxDebtDelta);
        }
    }

    /// @notice Calculates the excess debt of a strategy.
    /// @param _strategy The address of the strategy for which to determine the debt excess.
    /// @return The amount of excess debt for the given strategy.
    function _debtExcess(address _strategy) internal view returns (uint256) {
        if(debtRatio == 0) {
            return strategies[_strategy].totalDebt;
        }

        uint256 sDebtLimit = strategies[_strategy].debtRatio.mulDiv(totalAssets(), Constants.MAX_BPS, Math.Rounding.Floor);
        uint256 sTotalDebt = strategies[_strategy].totalDebt;

        if(sTotalDebt <= sDebtLimit) {
            return 0;
        } else {
            return sTotalDebt - sDebtLimit;
        }
    }
    
    /// @notice Calculates the free funds available in the contract.
    /// @return The amount of free funds available.
    function _freeFunds() internal view returns (uint256) {
        return totalAssets() - _calculateLockedProfit();
    }

    /// @notice Calculate the current locked profit.
    /// @dev Locked profit degrades linearly over 3 days from the initial amount to zero.
    /// Calculated as: initialLockedProfit * (1 - timeElapsed / 3 days), where timeElapsed
    /// is the time since last report. Returns 0 after 3 days.
    /// @return newLockedProfit The calculated current locked profit.
    function _calculateLockedProfit() internal view returns (uint256 newLockedProfit) {
        // 3 days in seconds * LOCKED_PROFIT_DEGRADATION = 1 ether
        uint256 lockedFundsRatio = (block.timestamp - lastReport) * LOCKED_PROFIT_DEGRADATION;
        if(lockedFundsRatio < 1 ether) {
            newLockedProfit = lockedProfit - lockedFundsRatio.mulDiv(lockedProfit, 1 ether, Math.Rounding.Floor);
        }
        return newLockedProfit;
    }

    /// @notice Calculates slippage based on exchange rate degradation between expected and actual values
    /// @param _expectedAssets Expected asset amount before settling unrealized losses
    /// @param _actualAssets Actual asset amount after settling unrealized losses  
    /// @param _expectedShares Expected share amount before settling unrealized losses
    /// @param _actualShares Actual share amount after settling unrealized losses
    function _checkSlippage(
        uint256 _expectedAssets,
        uint256 _actualAssets, 
        uint256 _expectedShares,
        uint256 _actualShares
    ) internal view {
        if (_actualAssets == 0 || _actualShares == 0) revert Errors.SlippageCheckFailed(Constants.MAX_BPS, slippageLimit);
        if (_expectedAssets == 0 || _expectedShares == 0) return;
        
        uint256 expectedExchangeRate = _expectedAssets.mulDiv(10**36, _expectedShares, Math.Rounding.Floor);
        uint256 actualExchangeRate = _actualAssets.mulDiv(10**36, _actualShares, Math.Rounding.Floor);
        uint256 slippage = 
            expectedExchangeRate > actualExchangeRate ? 
            (expectedExchangeRate - actualExchangeRate).mulDiv(Constants.MAX_BPS, expectedExchangeRate, Math.Rounding.Ceil)
            : 0;
        require(slippage <= slippageLimit, Errors.SlippageCheckFailed(slippage, slippageLimit));
    }

    /// @notice Calculates the current profit and loss (PnL) across all active strategies.
    /// @return totalProfit The total profit across all active strategies, after deducting the performance fee.
    /// @return totalLoss The total loss across all active strategies.
    function _currentPnL() internal view returns (uint256 totalProfit, uint256 totalLoss) {
        uint256 nStrategies = withdrawOrder.length;
        if (nStrategies == 0) return (0, 0);

        for(uint256 i = 0; i < nStrategies; ++i){
            address strategy = withdrawOrder[i];
            (uint256 gain, uint256 loss) = IAdapter(strategy).currentPnL();
            totalProfit += gain.mulDiv(Constants.MAX_BPS - performanceFee, Constants.MAX_BPS, Math.Rounding.Floor);
            totalLoss += loss;
        }

        if (totalProfit > 0 && totalLoss > 0) {
            if(totalProfit >= totalLoss) {
                totalProfit -= totalLoss;
                totalLoss = 0;
            } else {
                totalLoss -= totalProfit;
                totalProfit = 0;
            }
        }
        return (totalProfit, totalLoss);
    }

    /// @notice Calculates the liquidity available to fulfill withdraws
    /// @dev When an adapter doesn't have enough liquidity. All the liquidity in subsequent adapters
    /// will not be able reachable, due to how the withdraw process works.
    /// @return liquidity The amount of liquidity that is available
    function _availableLiquidity() internal view returns (uint256 liquidity) {
        liquidity = _balance();
        uint256 nStrategies = withdrawOrder.length;
        for(uint256 i = 0; i < nStrategies; ++i) {
            uint256 strategyTotalAssets = IAdapter(withdrawOrder[i]).totalAssets();
            uint256 strategyAvailableLiquidity = IAdapter(withdrawOrder[i]).availableLiquidity();
            liquidity += Math.min(strategyTotalAssets, strategyAvailableLiquidity);

            if(strategyTotalAssets > strategyAvailableLiquidity) break;
        }
    }

    /// @notice The difference between 18 and the asset's decimals.
    /// @return The decimal offset.
    function _decimalsOffset() internal view override returns (uint8) {
        return DECIMALS_OFFSET;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Handles deposits into the contract.
    /// @param _caller The address of the entity initiating the deposit.
    /// @param _receiver The address of the recipient to receive the shares.
    /// @param _assets The amount of assets being deposited.
    /// @param _shares The number of shares to be minted for the receiver.
    function _enter(address _caller, address _receiver, uint256 _assets, uint256 _shares) internal {
        require(_receiver != address(0) && _receiver != address(this), Errors.InvalidAddress(_receiver));
        require(_assets > 0, Errors.ZeroAmount(_assets));

        IERC20(asset()).safeTransferFrom(_caller, address(this), _assets);
        _mint(_receiver, _shares);

        emit Deposit(_caller, _receiver, _assets, _shares);
    }

    /// @notice Handles withdrawals from the contract.
    /// @param _caller The address of the entity initiating the withdrawal.
    /// @param _receiver The address of the recipient to receive the withdrawn assets.
    /// @param _owner The address of the owner of the shares being withdrawn.
    /// @param _assets The amount of assets to withdraw.
    /// @param _shares The amount of shares to burn.
    function _exit(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _assets,
        uint256 _shares
    ) internal {
        require(_receiver != address(0) && _receiver != address(this), Errors.InvalidAddress(_receiver));
        require(_shares > 0, Errors.ZeroAmount(_shares));

        if (_caller != _owner) _spendAllowance(_owner, _caller, _shares);
        if (_assets > _balance()) {
            uint256 nStrategies = withdrawOrder.length;
            for(uint256 i = 0; i < nStrategies; ++i){
                address strategy = withdrawOrder[i];
                uint256 assetsToWithdraw = (_assets - _balance())
                                                .min(strategies[strategy].totalDebt)
                                                .min(IAdapter(strategy).availableLiquidity());
                if(assetsToWithdraw == 0) continue;

                uint256 withdrawn = IAdapter(strategy).withdraw(assetsToWithdraw);
                strategies[strategy].totalDebt -= withdrawn;
                totalDebt -= withdrawn;

                if(_assets <= _balance()) break;
            }
        }
        _burn(_owner, _shares);
        IERC20(asset()).safeTransfer(_receiver, _assets);

        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    /// @notice Requests credit for an active strategy.
    /// @dev This function should be called only by active strategies when they need to request credit.
    /// @return credit The amount of credit requested by msg.sender
    function _requestCredit() internal returns (uint256 credit){
        credit = _creditAvailable(msg.sender);

        if(credit > 0) {
            strategies[msg.sender].totalDebt += credit;
            totalDebt += credit;
            IERC20(asset()).safeTransfer(msg.sender, credit);
            emit CreditRequested(msg.sender, credit);
        }
    }

    /// @notice Reports the performance of a strategy.
    /// @param _debtRepayment The amount of debt being repaid by the strategy.
    /// @param _gain The amount of profit reported by the strategy.
    /// @param _loss The amount of loss reported by the strategy.
    function _report(uint256 _debtRepayment, uint256 _gain, uint256 _loss) internal {
        uint256 strategyBalance = IERC20(asset()).balanceOf(msg.sender);
        require(!(_gain > 0 && _loss > 0), Errors.GainLossMismatch());
        require(strategyBalance >= _debtRepayment + _gain, Errors.InsufficientBalance(strategyBalance, _debtRepayment + _gain));

        uint256 profit = 0;
        uint256 feesCollected = 0;
        if(_loss > 0) _settleLoss(msg.sender, _loss);
        if(_gain > 0) {
            strategies[msg.sender].totalGain += _gain;
            feesCollected = _gain.mulDiv(performanceFee, Constants.MAX_BPS, Math.Rounding.Floor);
            profit = _gain - feesCollected;
        } 

        uint256 debtToRepay = Math.min(_debtRepayment, _debtExcess(msg.sender));
        if(debtToRepay > 0) {
            strategies[msg.sender].totalDebt -= debtToRepay;
            totalDebt -= debtToRepay;
        }
        
        uint256 newLockedProfit = _calculateLockedProfit() + profit;
        lockedProfit = newLockedProfit > _loss ? newLockedProfit - _loss : 0;

        strategies[msg.sender].lastReport = block.timestamp.toUint32();
        lastReport = block.timestamp;

        if(debtToRepay + _gain > 0) IERC20(asset()).safeTransferFrom(msg.sender, address(this), debtToRepay + _gain);
        if(feesCollected > 0) IERC20(asset()).safeTransfer(protocolFeeRecipient, feesCollected);

        emit StrategyReported(msg.sender, debtToRepay, _gain, _loss);
        emit Earn(convertToAssets(1 ether), lockedProfit);
    }

    /// @notice Loops through the active strategies and settles any unrealized loss.
    /// @dev To be executed before any withdraw or redeem. Adds loss front-running protection
    function _settleUnrealizedLosses() internal {
        uint256 nStrategies = withdrawOrder.length;
        for(uint256 i = 0; i < nStrategies; ++i){
            address strategy = withdrawOrder[i];
            if(strategies[strategy].totalDebt == 0) continue;
            
            (, uint256 loss) = IAdapter(strategy).currentPnL();
            if(loss > 0) IAdapter(strategy).askReport();
        }
    }

    /// @notice Settles a loss for a strategy.
    /// @param _strategy The address of the strategy reporting the loss.
    /// @param _loss The amount of loss reported by the strategy.
    function _settleLoss(address _strategy, uint256 _loss) internal {
        require(_loss > 0 && _loss <= strategies[_strategy].totalDebt, Errors.InvalidStrategyLoss());

        strategies[_strategy].totalLoss += _loss;
        strategies[_strategy].totalDebt -= _loss;
        totalDebt -= _loss;
    }
}