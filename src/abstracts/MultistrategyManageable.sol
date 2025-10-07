// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { MultistrategyAdminable } from "./MultistrategyAdminable.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";
import { IStrategyAdapter } from "interfaces/IStrategyAdapter.sol";
import { Constants } from "../libraries/Constants.sol";
import { MStrat } from "../libraries/DataTypes.sol";
import { Errors } from "../libraries/Errors.sol";

abstract contract MultistrategyManageable is IMultistrategyManageable, MultistrategyAdminable {
    
    /// @inheritdoc IMultistrategyManageable
    address public protocolFeeRecipient;

    /// @inheritdoc IMultistrategyManageable
    uint256 public performanceFee;

    /// @inheritdoc IMultistrategyManageable
    uint256 public depositLimit;

    /// @inheritdoc IMultistrategyManageable
    uint256 public debtRatio;

    /// @inheritdoc IMultistrategyManageable
    uint256 public totalDebt;

    /// @inheritdoc IMultistrategyManageable
    uint256 public slippageLimit;

    /// @inheritdoc IMultistrategyManageable
    uint8 public activeStrategies;

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Strategy parameters mapped by the strategy address
    mapping(address strategyAddress => MStrat.StrategyParams strategyParameters) public strategies;

    /// @notice Order that `_withdraw()` uses to determine which strategy pull the funds from.
    address[] public withdrawOrder;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Initial owner is the deployer of the multistrategy.
    /// @param _owner Address of the initial Multistrategy owner.
    /// @param _manager Address of the initial Multistrategy manager.
    /// @param _protocolFeeRecipient Address that will receive the performance fee.
    constructor(
        address _owner,
        address _manager,
        address _protocolFeeRecipient
    ) 
        MultistrategyAdminable(_owner, _manager) 
    {
        require(_protocolFeeRecipient != address(0), Errors.ZeroAddress());

        protocolFeeRecipient = _protocolFeeRecipient;
        withdrawOrder = new address[](Constants.MAXIMUM_STRATEGIES);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Check if `_strategy` is active.
    /// @dev Reverts if `_strategy` is not active.
    /// @param _strategy Address of the strategy to check if it is active. 
    modifier onlyActiveStrategy(address _strategy) {
        require(strategies[_strategy].activation > 0, Errors.StrategyNotActive(_strategy));
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMultistrategyManageable
    function getWithdrawOrder() external view returns (address[] memory) {
        return withdrawOrder;
    }

    /// @inheritdoc IMultistrategyManageable
    function getStrategyParameters(address _strategy) external view returns (MStrat.StrategyParams memory) {
        return strategies[_strategy];
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMultistrategyManageable
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), Errors.ZeroAddress());

        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientSet(protocolFeeRecipient);
    }

    /// @inheritdoc IMultistrategyManageable
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= Constants.MAX_PERFORMANCE_FEE, Errors.ExcessiveFee(_performanceFee));

        performanceFee = _performanceFee;
        emit PerformanceFeeSet(performanceFee);
    }

    /// @inheritdoc IMultistrategyManageable
    function setDepositLimit(uint256 _depositLimit) external onlyManager {
        depositLimit = _depositLimit;
        emit DepositLimitSet(depositLimit);
    }

    /// @inheritdoc IMultistrategyManageable
    function setSlippageLimit(uint256 _slippageLimit) external onlyManager {
        require(_slippageLimit <= Constants.MAX_BPS, Errors.SlippageLimitExceeded(_slippageLimit));
        
        slippageLimit = _slippageLimit;
        emit SlippageLimitSet(slippageLimit);
    }

    /// @inheritdoc IMultistrategyManageable
    function setWithdrawOrder(address[] memory _strategies) external onlyManager {
        require(_validateStrategyOrder(_strategies), Errors.InvalidWithdrawOrder());

        withdrawOrder = _strategies;
        emit WithdrawOrderSet();
    }

    /// @inheritdoc IMultistrategyManageable
    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _minDebtDelta,
        uint256 _maxDebtDelta
    ) external onlyOwner {
        require(activeStrategies < Constants.MAXIMUM_STRATEGIES, Errors.MaximumAmountStrategies());
        require(_strategy != address(0) && _strategy != address(this), Errors.InvalidStrategy(_strategy));
        require(IStrategyAdapter(_strategy).multistrategy() == address(this), Errors.InvalidStrategy(_strategy));
        require(strategies[_strategy].activation == 0, Errors.StrategyAlreadyActive(_strategy));
        require(debtRatio + _debtRatio <=  Constants.MAX_BPS, Errors.DebtRatioAboveMaximum(debtRatio + _debtRatio));
        require(_minDebtDelta <= _maxDebtDelta, Errors.InvalidDebtDelta());

        strategies[_strategy] = MStrat.StrategyParams({
            activation: block.timestamp,
            debtRatio: _debtRatio,
            lastReport: block.timestamp,
            minDebtDelta: _minDebtDelta,
            maxDebtDelta: _maxDebtDelta,
            totalDebt: 0,
            totalGain: 0,
            totalLoss: 0
        });

        debtRatio += _debtRatio;
        withdrawOrder[activeStrategies] = _strategy;
        ++activeStrategies;

        emit StrategyAdded(_strategy);
    }

    /// @inheritdoc IMultistrategyManageable
    function removeStrategy(address _strategy) external onlyManager onlyActiveStrategy(_strategy) {
        require(strategies[_strategy].debtRatio == 0, Errors.StrategyWithActiveDebtRatio());
        require(strategies[_strategy].totalDebt == 0, Errors.StrategyWithActiveDebt());

        for(uint8 i = 0; i < Constants.MAXIMUM_STRATEGIES; ++i) {
            if(withdrawOrder[i] == _strategy) {
                withdrawOrder[i] = address(0);
                delete strategies[_strategy];
                --activeStrategies;
                _organizeWithdrawOrder();

                emit StrategyRemoved(_strategy);
                return;
            }
        }
    }

    /// @inheritdoc IMultistrategyManageable
    function setStrategyDebtRatio(address _strategy, uint256 _debtRatio) external onlyManager onlyActiveStrategy(_strategy) {
        uint256 newDebtRatio = debtRatio - strategies[_strategy].debtRatio + _debtRatio;
        require(newDebtRatio <= Constants.MAX_BPS, Errors.DebtRatioAboveMaximum(newDebtRatio));

        debtRatio = newDebtRatio;
        strategies[_strategy].debtRatio = _debtRatio;

        emit StrategyDebtRatioSet(_strategy, _debtRatio);
    }

    /// @inheritdoc IMultistrategyManageable
    function setStrategyMinDebtDelta(address _strategy, uint256 _minDebtDelta) external onlyManager onlyActiveStrategy(_strategy) {
        require(strategies[_strategy].maxDebtDelta >= _minDebtDelta, Errors.InvalidDebtDelta());

        strategies[_strategy].minDebtDelta = _minDebtDelta;

        emit StrategyMinDebtDeltaSet(_strategy, _minDebtDelta);
    }

    /// @inheritdoc IMultistrategyManageable
    function setStrategyMaxDebtDelta(address _strategy, uint256 _maxDebtDelta) external onlyManager onlyActiveStrategy(_strategy) {
        require(strategies[_strategy].minDebtDelta <= _maxDebtDelta, Errors.InvalidDebtDelta());

        strategies[_strategy].maxDebtDelta = _maxDebtDelta;

        emit StrategyMaxDebtDeltaSet(_strategy, _maxDebtDelta);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Validates the order of strategies for withdrawals.
    /// @param _strategies The array of strategy addresses to validate.
    /// @return True if the order is valid. False if not valid.
    function _validateStrategyOrder(address[] memory _strategies) internal view returns (bool) {
        if(_strategies.length != Constants.MAXIMUM_STRATEGIES) return false;
        uint8 activeCount;
        for(uint8 i = 0; i < Constants.MAXIMUM_STRATEGIES; ++i) {
            address strategy = _strategies[i];
            if(strategy != address(0)) {
                if(strategies[strategy].activation == 0) return false;
                // Start to check on the next strategy
                for(uint8 j = i + 1; j < Constants.MAXIMUM_STRATEGIES; ++j) {
                    // Check that the strategy isn't duplicate
                    if(i != j && strategy == _strategies[j]) return false;
                }
                ++activeCount;
            } else {
                // Check that the rest of the addresses are address(0)
                for(uint8 j = i + 1; j < Constants.MAXIMUM_STRATEGIES; ++j) {
                    if(_strategies[j] != address(0)) return false;
                }
                break;
            }
        }
        return activeCount == activeStrategies;
    }

    /// @notice Organizes the withdraw order by removing gaps and shifting strategies.
    function _organizeWithdrawOrder() internal {
        uint8 position = 0;
        for(uint8 i = 0; i < Constants.MAXIMUM_STRATEGIES; ++i) {
            address strategy = withdrawOrder[i];
            if(strategy == address(0)) {
                ++position;
            } else if (position > 0) {
                withdrawOrder[i - position] = strategy;
                withdrawOrder[i] = address(0);
            }
        }
    }
}