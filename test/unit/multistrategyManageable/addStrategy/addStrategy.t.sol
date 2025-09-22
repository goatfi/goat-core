// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;


import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { Multistrategy } from "src/Multistrategy.sol";
import { MStrat } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { IMultistrategyManageable } from "interfaces/IMultistrategyManageable.sol";

contract AddStrategy_Integration_Concrete_Test is Multistrategy_Base_Test {
    uint256 debtRatio = 5_000;
    uint256 minDebtDelta = 100 ether;
    uint256 maxDebtDelta = 100_000 ether;

    function test_RevertWhen_CallerNotOwner() external {
        address strategy = makeAddr("strategy");
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, users.bob));
        vm.prank(users.bob); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_RevertWhen_ActiveStrategiesAboveMaximum() 
        external 
        whenCallerIsOwner
    {
        // Deploy 10 strategies, each with 10% debt ratio
        for (uint256 i = 0; i < 10; i++) {
            _createAndAddAdapter(1_000, minDebtDelta, maxDebtDelta);
        }
        MockStrategyAdapter strategy = _createAdapter();

        vm.expectRevert(abi.encodeWithSelector(Errors.MaximumAmountStrategies.selector));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    modifier whenActiveStrategiesBelowMaximum() {
        _;
    }

    function test_RevertWhen_StrategyIsZeroAddress() 
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
    {
        address strategy = address(0);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategy.selector, strategy));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    modifier whenNotZeroAddress() {
        _;
    }

    function test_RevertWhen_StrategyIsMultistrategyAddress()
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
        whenNotZeroAddress
    {
        address strategy = address(multistrategy);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategy.selector, strategy));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    modifier whenNotMultistrategyAddress() {
        _;
    }

    /// @dev Only way to activate a strategy is to add it to the multistrategy
    function test_RevertWhen_StrategyIsActive() 
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
        whenNotZeroAddress
        whenNotMultistrategyAddress
    {
        MockStrategyAdapter strategy = _createAdapter();
        // We add the strategy
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);

        vm.expectRevert(abi.encodeWithSelector(Errors.StrategyAlreadyActive.selector, strategy));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    modifier whenStrategyIsInactive() {
        _;
    }

    /// @dev Testing this requires some setup. As creating a strategy with the wrong base asset
    ///      would revert, as it is checked in the constructor of the StrategyAdapter.
    ///      We need to deploy a need multistrategy with a different token and create a strategy for
    ///      that multistrategy.
    function test_RevertWhen_AssetDoNotMatch() 
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
        whenNotZeroAddress
        whenNotMultistrategyAddress
        whenStrategyIsInactive
    {
        vm.prank(users.owner); Multistrategy newMultistrategy = new Multistrategy({
            _asset: address(dai),
            _manager: users.manager,
            _protocolFeeRecipient: users.feeRecipient,
            _name: "Multistrategy",
            _symbol: "MULT"
        });
        
        // Deploy a mock strategy for the usdt multistrategy
        vm.prank(users.manager); MockStrategyAdapter strategyWithWrongMulti = new MockStrategyAdapter(address(newMultistrategy));
        
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidStrategy.selector, address(strategyWithWrongMulti)));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategyWithWrongMulti), debtRatio, minDebtDelta, maxDebtDelta);
    }

    modifier whenAssetMatch() {
        _;
    }

    function test_RevertWhen_DebtRatioSumIsAboveMax()
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
        whenNotZeroAddress
        whenNotMultistrategyAddress
        whenStrategyIsInactive
        whenAssetMatch
    {
        MockStrategyAdapter strategy = _createAdapter();
        debtRatio = 11_000;

        vm.expectRevert(abi.encodeWithSelector(Errors.DebtRatioAboveMaximum.selector, debtRatio));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    /// @dev Le = Lower or Equal
    modifier whenDebtRatioLeMax() {
        _;
    }

    function test_RevertWhen_MinDebtDeltaIsHigherThanMaxDebtDelta()
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
        whenNotZeroAddress
        whenNotMultistrategyAddress
        whenStrategyIsInactive
        whenAssetMatch
        whenDebtRatioLeMax
    {
        MockStrategyAdapter strategy = _createAdapter();
        minDebtDelta = 200_000 ether;
        maxDebtDelta = 100_000 ether;

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidDebtDelta.selector));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);
    }

    /// @dev Le = Lower or Equal
    modifier whenMinDebtDeltaLeMaxDebtDelta() {
        _;
    }

    function test_AddStrategy_NewStrategy()
        external
        whenCallerIsOwner
        whenActiveStrategiesBelowMaximum
        whenNotZeroAddress
        whenNotMultistrategyAddress
        whenStrategyIsInactive
        whenAssetMatch
        whenMinDebtDeltaLeMaxDebtDelta
    {
        MockStrategyAdapter strategy = _createAdapter();

        // Expect the relevant event
        vm.expectEmit({ emitter: address(multistrategy) });
        emit IMultistrategyManageable.StrategyAdded(address(strategy));

        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), debtRatio, minDebtDelta, maxDebtDelta);

        MStrat.StrategyParams memory actualStrategyParams = multistrategy.getStrategyParameters(address(strategy));
        MStrat.StrategyParams memory expectedStrategyParams = MStrat.StrategyParams({
            activation: block.timestamp,
            debtRatio: debtRatio,
            lastReport: block.timestamp,
            minDebtDelta: minDebtDelta,
            maxDebtDelta: maxDebtDelta,
            totalDebt: 0,
            totalGain: 0,
            totalLoss: 0
        });

        uint256 actualMultistrategyDebtRatio = multistrategy.debtRatio();
        uint256 expectedMultistrategyDebtRatio = debtRatio;

        uint256 actualActiveStrategies = multistrategy.activeStrategies();
        uint256 expectedActiveStrategies = 1;

        address actualAddressAtWithdrawOrderPos0 = multistrategy.getWithdrawOrder()[0];
        address expectedAddressAtWithdrawOrderPos0 = address(strategy);
        
        // Assert strategy params
        assertEq(actualStrategyParams.activation, expectedStrategyParams.activation, "addStrategy Params activation");
        assertEq(actualStrategyParams.debtRatio, expectedStrategyParams.debtRatio, "addStrategy Params debtRatio");
        assertEq(actualStrategyParams.lastReport, expectedStrategyParams.lastReport, "addStrategy Params last report");
        assertEq(actualStrategyParams.minDebtDelta, expectedStrategyParams.minDebtDelta, "addStrategy Params min debt delta");
        assertEq(actualStrategyParams.maxDebtDelta, expectedStrategyParams.maxDebtDelta, "addStrategy Params max debt delta");
        assertEq(actualStrategyParams.totalDebt, expectedStrategyParams.totalDebt, "addStrategy Params total debt");
        assertEq(actualStrategyParams.totalGain, expectedStrategyParams.totalGain, "addStrategy Params total gain");
        assertEq(actualStrategyParams.totalLoss, expectedStrategyParams.totalLoss, "addStrategy Params total loss");

        // Assert strategy debt ratio is added to multistrategy debt ratio
        assertEq(actualMultistrategyDebtRatio, expectedMultistrategyDebtRatio, "addStrategy DebtRatio");

        // Assert active strategies is incremented
        assertEq(actualActiveStrategies, expectedActiveStrategies, "addStrategy Active strategies");

        // Assert that the strategy has been put in the 1st position of the withdraw order
        assertEq(actualAddressAtWithdrawOrderPos0, expectedAddressAtWithdrawOrderPos0, "addStrategy withdraw order");
    }
}