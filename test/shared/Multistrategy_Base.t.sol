// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Base_Test } from "./Base.t.sol";
import { MockStrategyAdapter } from "../mocks/MockStrategyAdapter.sol";
import { Multistrategy } from "src/Multistrategy.sol";

contract Multistrategy_Base_Test is Base_Test {

    Multistrategy multistrategy;

    function setUp() public virtual override {
        Base_Test.setUp();

        deployMultistrategy();
    }

    function deployMultistrategy() internal override {
        multistrategy = new Multistrategy({
            _asset: address(dai),
            _manager: users.manager,
            _protocolFeeRecipient: users.feeRecipient,
            _name: "Goat DAI",
            _symbol: "GDAI"
        });

        multistrategy.enableGuardian(users.guardian);
        multistrategy.setDepositLimit(100_000 * 10 ** dai.decimals());
        multistrategy.setPerformanceFee(1000);
        multistrategy.transferOwnership(users.owner);

        vm.label({ account: address(multistrategy), newLabel: "Multistrategy" });
    }

    function _createAdapter() internal returns (MockStrategyAdapter adapter) {
        vm.prank(users.manager); adapter = new MockStrategyAdapter(address(multistrategy), address(dai));
    }

    function _createAndAddAdapter(uint256 _debtRatio, uint256 _minDebtDelta, uint256 _maxDebtDelta) internal returns (MockStrategyAdapter adapter) {
        vm.prank(users.manager); adapter = new MockStrategyAdapter(address(multistrategy), address(dai));
        vm.prank(users.owner); multistrategy.addStrategy(address(adapter), _debtRatio, _minDebtDelta, _maxDebtDelta);
    }

    function _userDeposit(address _user, uint256 _amount) internal {
        dai.mint(_user, _amount);

        vm.prank(_user); dai.approve(address(multistrategy), _amount);
        vm.prank(_user); multistrategy.deposit(_amount, _user);
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public override {}
}