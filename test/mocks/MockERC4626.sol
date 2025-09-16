// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC4626 } from "solady/tokens/ERC4626.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/interfaces/IERC20.sol";
import { IMockERC20 } from "./MockERC20.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC4626 is ERC4626 {

    bool public immutable useVirtualShares;
    uint8 public immutable decimalsOffset;

    address internal immutable _underlying;
    uint8 internal immutable _decimals;

    string internal _name;
    string internal _symbol;

    uint256 public beforeWithdrawHookCalledCounter;
    uint256 public afterDepositHookCalledCounter;

    uint256 public borrowed;

    constructor(
        address underlying_,
        string memory name_,
        string memory symbol_,
        bool useVirtualShares_,
        uint8 decimalsOffset_
    ) {
        _underlying = underlying_;

        (bool success, uint8 result) = _tryGetAssetDecimals(underlying_);
        _decimals = success ? result : _DEFAULT_UNDERLYING_DECIMALS;

        _name = name_;
        _symbol = symbol_;

        useVirtualShares = useVirtualShares_;
        decimalsOffset = decimalsOffset_;
    }

    function borrow(uint256 _amount) external {
        require(_amount <= IERC20(asset()).balanceOf(address(this)), "Amount too high");
        IMockERC20(asset()).burn(address(this), _amount);
        borrowed += _amount;
    }

    function repay(uint256 _amount) external {
        require(_amount <= borrowed, "Amount too high");
        IMockERC20(asset()).mint(address(this), _amount);
        borrowed -= _amount;
    }

    function totalAssets() public view override returns (uint256 assets) {
        assets = IERC20(asset()).balanceOf(address(this)) + borrowed;
    }

    function asset() public view virtual override returns (address) {
        return _underlying;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _useVirtualShares() internal view virtual override returns (bool) {
        return useVirtualShares;
    }

    function _underlyingDecimals() internal view virtual override returns (uint8) {
        return _decimals;
    }

    function _decimalsOffset() internal view virtual override returns (uint8) {
        return decimalsOffset;
    }

    function _beforeWithdraw(uint256, uint256) internal override {
        unchecked {
            ++beforeWithdrawHookCalledCounter;
        }
    }

    function _afterDeposit(uint256, uint256) internal override {
        unchecked {
            ++afterDepositHookCalledCounter;
        }
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public {}
}