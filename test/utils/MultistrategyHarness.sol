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

    function reportLoss(address _strategy, uint256 _loss) external {
        _reportLoss(_strategy, _loss);
    }

    function profitUnlockTime() external pure returns (uint256) {
        return PROFIT_UNLOCK_TIME;
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public {}
}