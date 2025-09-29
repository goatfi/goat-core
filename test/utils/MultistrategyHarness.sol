// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Multistrategy } from "src/Multistrategy.sol";

contract MultistrategyHarness is Multistrategy {
    constructor(
        address _asset,
        address _manager,
        address _protocolFeeRecipient,
        string memory _name, 
        string memory _symbol
    ) 
        Multistrategy(
            _asset,
            _manager,
            _protocolFeeRecipient,
            _name,
            _symbol
        ) {}

    function calculateLockedProfit() external view returns(uint256) {
        return _calculateLockedProfit();
    }

    function balance() external view returns(uint256) {
        return _balance();
    }

    function freeFunds() external view returns(uint256) {
        return _freeFunds();
    }

    function settleLoss(address _strategy, uint256 _loss) external {
        _settleLoss(_strategy, _loss);
    }

    function enter(address _caller, address _receiver, uint256 _assets, uint256 _shares) external {
        _enter(_caller, _receiver, _assets, _shares);
    }

    function exit(address _caller, address _receiver, address _owner, uint256 _assets, uint256 _shares) external {
        _exit(_caller, _receiver, _owner, _assets, _shares);
    }

    function settleUnrealizedLosses() external {
        _settleUnrealizedLosses();
    }

    function checkSlippage(
        uint256 _expectedAssets,
        uint256 _actualAssets,
        uint256 _expectedShares,
        uint256 _actualShares
    ) external view {
        _checkSlippage(_expectedAssets, _actualAssets, _expectedShares, _actualShares);
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public {}
}