// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IERC20, SafeERC20 } from "../../dependencies/@openzeppelin-contracts-5.4.0/token/ERC20/utils/SafeERC20.sol";
import { StrategyAdapter } from "../../src/abstracts/StrategyAdapter.sol";
import { MockERC4626 } from "../../test/mocks/MockERC4626.sol";

contract Adapter is StrategyAdapter {
    using SafeERC20 for IERC20;

    MockERC4626 public vault;

    constructor(
        address _multistrategy
    ) 
        StrategyAdapter(_multistrategy, "Mock", "MOCK") 
    {
        vault = new MockERC4626(asset, "Staked DAI", "sDAI", false, 0);
        _giveAllowances();
    }

    function _deposit() internal override {
        vault.deposit(_balance(), address(this));
    }

    function _withdraw(uint256 _amount) internal override {
        vault.withdraw(_amount, address(this), address(this));
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
        uint256 vaultShares = vault.balanceOf(address(this));
        uint256 strategyBalance = vault.previewRedeem(vaultShares);
        return strategyBalance + _balance();
    }

    function _availableLiquidity() internal override view returns(uint256) {
        return IERC20(asset).balanceOf(address(vault));
    }
}