// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { Multistrategy } from "../../src/Multistrategy.sol";

contract MultistrategyHarness is Multistrategy {
    constructor(
        address _asset,
        address _owner,
        address _manager,
        address _feeRecipient,
        string memory _name,
        string memory _symbol
    ) Multistrategy(_asset, _owner, _manager, _feeRecipient, _name, _symbol){}

    function getStrategyDebtRatio(address _strategy) external view returns(uint256) {
        return strategies[_strategy].debtRatio;
    }

    function withdrawOrderIsValid() external view returns (bool) {
        for (uint256 i = 0; i < withdrawOrder.length; i++) {
            address strategy = withdrawOrder[i];
            if (strategy == address(0)) return false;
            if (strategies[strategy].queueIndex != i) return false;
            if (strategies[strategy].lastReport == 0) return false;
        }
        return true;
    }

    function reentrancyGuardEntered() external view returns (bool) {
        return _reentrancyGuardEntered();
    }
}