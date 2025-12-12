// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Adapter } from "src/abstracts/Adapter.sol";

abstract contract AdapterHarness is Adapter {

    constructor(
        address _multistrategy,
        string memory _name,
        string memory _id
    ) Adapter(_multistrategy, _name, _id) {}

    function balance() external view returns (uint256) {
        return _balance();
    }

    function calculateGainAndLoss(uint256 _currentAssets) external view returns(uint256 gain, uint256 loss) {
        (gain, loss) = _calculateGainAndLoss(_currentAssets);
        return (gain, loss);
    }

    function tryWithdraw(uint256 _amount) external {
        _tryWithdraw(_amount);
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public virtual {}
}