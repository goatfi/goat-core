// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20, SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { IMockERC20 } from "./MockERC20.sol";
import { MockERC4626 } from "./MockERC4626.sol";
import { StrategyAdapter } from "src/abstracts/StrategyAdapter.sol";

contract MockStrategyAdapter is StrategyAdapter {
    using SafeERC20 for IERC20;

    MockERC4626 vault;
    uint256 slippage;

    constructor(
        address _multistrategy,
        address _asset
    ) 
        StrategyAdapter(_multistrategy, _asset, "Mock", "MOCK") 
    {
        vault = new MockERC4626(_asset, "Staked DAI", "sDAI", false, 0);
        _giveAllowances();
    }

    function balance() external view returns (uint256) {
        return _balance();
    }

    function earn(uint256 _amount) external {
        IMockERC20(asset).mint(address(vault), _amount);
    }

    function lose(uint256 _amount) external {
        IMockERC20(asset).burn(address(vault), _amount);
    }

    function setStakingSlippage(uint256 _slippage) external {
        slippage = _slippage;
    }

    function tryWithdraw(uint256 _amount) external {
        _tryWithdraw(_amount);
    }

    function calculateGainAndLoss(uint256 _currentAssets) external view returns(uint256 gain, uint256 loss) {
        (gain, loss) = _calculateGainAndLoss(_currentAssets);
        return (gain, loss);
    }

    function calculateAmountToBeWithdrawn(uint256 _repayAmount, uint256 _strategyGain) external view returns(uint256) {
        return _calculateAmountToBeWithdrawn(_repayAmount, _strategyGain);
    }

    function withdrawFromStaking(uint256 _amount) external {
        _withdraw(_amount);
    }

    function _deposit() internal override {
        vault.deposit(_balance(), address(this));
    }

    function _withdraw(uint256 _amount) internal override {
        vault.withdraw(_amount, address(this), address(this));
        uint256 lostAmount = Math.mulDiv(_amount, slippage, MAX_SLIPPAGE);
        IERC20(asset).transfer(address(42069), lostAmount);
    }

    function _emergencyWithdraw() internal override {
        uint256 vaultBalance = vault.balanceOf(address(this));
        vault.redeem(vaultBalance, address(this), address(this));
    }

    function _revokeAllowances() internal override {
        IERC20(asset).forceApprove(address(vault), 0);
    }

    function _giveAllowances() internal override {
        IERC20(asset).forceApprove(address(vault), type(uint256).max);
    }

    function _totalAssets() internal override view returns(uint256) {
        uint256 strategyBalance = IERC20(asset).balanceOf(address(vault));
        return strategyBalance + _balance();
    }

    function _availableLiquidity() internal override view returns(uint256) {
        return vault.totalAssets();
    }
}