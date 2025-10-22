// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IERC20, SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { IMockERC20 } from "./MockERC20.sol";
import { MockERC4626 } from "./MockERC4626.sol";
import { StrategyAdapterHarness } from "../utils/StrategyAdapterHarness.sol";
import { Constants } from "../../src/libraries/Constants.sol";

contract MockStrategyAdapter is StrategyAdapterHarness {
    using SafeERC20 for IERC20;

    MockERC4626 public vault;
    uint256 slippage;
    uint256 surplus;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        address _multistrategy
    ) 
        StrategyAdapterHarness(_multistrategy, "Mock", "MOCK") 
    {
        vault = new MockERC4626(asset, "Staked DAI", "sDAI", false, 0);
        _giveAllowances();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MOCK HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function earn(uint256 _amount) external {
        IMockERC20(asset).mint(address(vault), _amount);
    }

    function lose(uint256 _amount) external {
        IMockERC20(asset).burn(address(vault), _amount);
    }

    function setStakingSlippage(uint256 _slippage) external {
        slippage = _slippage;
    }

    function setStakingSurplus(uint256 _surplus) external {
        surplus = _surplus;
    }

    function withdrawFromStaking(uint256 _amount) external {
        _withdraw(_amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MOCK IMPLEMENTATIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _deposit() internal override {
        vault.deposit(_balance(), address(this));
    }

    function _withdraw(uint256 _amount) internal override {
        require(!(surplus > 0 && slippage > 0), "Surplus and slippage cannot both be positive");
        vault.withdraw(_amount, address(this), address(this));
        if(surplus > 0) {
            uint256 earnedAmount = Math.mulDiv(_amount, surplus, Constants.MAX_BPS);
            IMockERC20(asset).mint(address(this), earnedAmount);
        } else {
            uint256 lostAmount = Math.mulDiv(_amount, slippage, Constants.MAX_BPS);
            IERC20(asset).safeTransfer(address(42069), lostAmount);
        }
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

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public override {}
}