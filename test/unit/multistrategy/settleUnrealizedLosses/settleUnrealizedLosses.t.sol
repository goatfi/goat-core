// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { MockStrategyAdapter } from "../../../mocks/MockStrategyAdapter.sol";

contract SettleUnrealizedLosses_Integration_Concrete_Test is MultistrategyHarness_Base_Test {
    MockStrategyAdapter adapter;

    function test_SettleUnrealizedLosses_NoActiveStrategies() external {
        uint256 initialLockedProfit = multistrategy.lockedProfit();

        multistrategy.settleUnrealizedLosses();

        uint256 finalLockedProfit = multistrategy.lockedProfit();
        assertEq(finalLockedProfit, initialLockedProfit, "lockedProfit should not be modified when no active strategies");
    }

    modifier whenThereAreActiveStrategies() {
        adapter = _createAndAddAdapter(5000, 0, type(uint256).max); // debtRatio 50%
        _;
    }

    function test_SettleUnrealizedLosses_DebtRatioZero()
        external
        whenThereAreActiveStrategies
    {
        vm.prank(users.owner); multistrategy.setStrategyDebtRatio(address(adapter), 0);
        

        uint256 initialLockedProfit = multistrategy.lockedProfit();

        multistrategy.settleUnrealizedLosses();

        uint256 finalLockedProfit = multistrategy.lockedProfit();
        assertEq(finalLockedProfit, initialLockedProfit, "lockedProfit should not be modified when strategy debtRatio is 0");
    }

    modifier whenStrategyDebtRatioIsHigherThanZero() {
        _userDeposit(users.alice, 1000 ether);
        vm.prank(users.manager); adapter.requestCredit();
        _;
    }

    function test_SettleUnrealizedLosses_NoLoss()
        external
        whenThereAreActiveStrategies
        whenStrategyDebtRatioIsHigherThanZero
    {
        adapter.earn(100 ether);

        uint256 initialLockedProfit = multistrategy.lockedProfit();

        multistrategy.settleUnrealizedLosses();

        uint256 finalLockedProfit = multistrategy.lockedProfit();
        assertEq(finalLockedProfit, initialLockedProfit, "lockedProfit should not be modified when strategy has no loss");
    }

    modifier whenStrategyHasLockedProfit(uint256 _profit) {
        adapter.earn(_profit);
        vm.prank(users.manager); adapter.sendReport(0);
        _;
    }

    modifier whenStrategyHasALoss(uint256 _loss) {
        adapter.lose(_loss);
        _;
    }

    function test_SettleUnrealizedLosses_LossLowerThanLockedProfit()
        external
        whenThereAreActiveStrategies
        whenStrategyDebtRatioIsHigherThanZero
        whenStrategyHasLockedProfit(200 ether)
        whenStrategyHasALoss(100 ether)
    {
        uint256 initialLockedProfit = multistrategy.lockedProfit();

        uint256 loss = 100 ether; // As set earlier

        require(initialLockedProfit > loss, "Setup failed: lockedProfit not > loss");

        uint256 initialStrategyTotalLoss = multistrategy.getStrategyParameters(address(adapter)).totalLoss;

        multistrategy.settleUnrealizedLosses();

        uint256 finalLockedProfit = multistrategy.lockedProfit();
        uint256 finalStrategyTotalLoss = multistrategy.getStrategyParameters(address(adapter)).totalLoss;

        assertEq(finalLockedProfit, initialLockedProfit - loss, "lockedProfit should be reduced by the loss");
        assertEq(finalStrategyTotalLoss, initialStrategyTotalLoss + loss, "loss should be added to strategy data");
    }

    function test_SettleUnrealizedLosses_LossHigherThanLockedProfit()
        external
        whenThereAreActiveStrategies
        whenStrategyDebtRatioIsHigherThanZero
        whenStrategyHasLockedProfit(100 ether)
        whenStrategyHasALoss(200 ether)
    {
        // Ensure lockedProfit < loss
        // Since initial lockedProfit is 0, and loss = 100 ether, 0 < 100

        uint256 initialLockedProfit = multistrategy.lockedProfit();
        uint256 loss = 200 ether;

        // Ensure initialLockedProfit < loss
        require(initialLockedProfit < loss, "Setup failed: lockedProfit not < loss");

        // Check initial conversion rate
        uint256 shares = 100 ether;
        uint256 initialAssets = multistrategy.previewRedeem(shares);

        multistrategy.settleUnrealizedLosses();

        uint256 finalLockedProfit = multistrategy.lockedProfit();
        uint256 finalAssets = multistrategy.previewRedeem(shares);

        assertEq(finalLockedProfit, 0, "lockedProfit should be set to 0");
        assertLt(finalAssets, initialAssets, "conversion from shares to assets should increase (higher value)");
    }
}