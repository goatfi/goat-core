// SPDX-License-Identifier: GNU AGPLv3

pragma solidity 0.8.30;

import { Multistrategy } from "../../src/Multistrategy.sol";

contract MultistrategyHarness is Multistrategy {
    constructor(
        address _asset,
        address _manager,
        address _feeRecipient,
        string memory _name,
        string memory _symbol
    ) Multistrategy(_asset, _manager, _feeRecipient, _name, _symbol){}

    function getStrategyDebtRatio(address _strategy) external view returns(uint256) {
        return strategies[_strategy].debtRatio;
    }
}