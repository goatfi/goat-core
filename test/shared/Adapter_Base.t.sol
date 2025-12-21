// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Base_Test } from "./Base.t.sol";
import { Multistrategy } from "src/Multistrategy.sol";
import { MockAdapter } from "../mocks/MockAdapter.sol";

contract Adapter_Base_Test is Base_Test {

    Multistrategy internal multistrategy;
    MockAdapter internal strategy;

    function setUp() public virtual override {
        super.setUp();
        deployMultistrategy();
        _createAndAddAdapter();
    }

    function deployMultistrategy() internal override {
        multistrategy = new Multistrategy({
            _asset: address(dai),
            _owner: users.owner,
            _manager: users.manager,
            _protocolFeeRecipient: users.feeRecipient,
            _name: "Goat DAI",
            _symbol: "GDAI"
        });

        vm.startPrank(users.owner);
        multistrategy.enableGuardian(users.guardian);
        multistrategy.setDepositLimit(100_000 * 10 ** dai.decimals());
        multistrategy.setPerformanceFee(1000);
        vm.stopPrank();

        vm.label({ account: address(multistrategy), newLabel: "Multistrategy" });
    }

    function _createAndAddAdapter() internal {
        strategy = new MockAdapter(users.manager, address(multistrategy));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), 10_000, 0, type(uint256).max);
    }

    function _createAndAddAdapter(uint256 _debtRatio, uint256 _minDebtDelta, uint256 _maxDebtDelta) internal {
        strategy = new MockAdapter(users.manager, address(multistrategy));
        vm.prank(users.owner); multistrategy.addStrategy(address(strategy), _debtRatio, _minDebtDelta, _maxDebtDelta);
    }

    function _userDeposit(address _user, uint256 _amount) internal {
        dai.mint(_user, _amount);

        vm.prank(_user); dai.approve(address(multistrategy), _amount);
        vm.prank(_user); multistrategy.deposit(_amount, _user);
    }

    function _requestCredit(uint256 _credit) internal {
        _userDeposit(users.bob, _credit);
        vm.prank(users.manager); strategy.requestCredit();
    }

    /// @dev Needed for the Test Coverage to ignore it.
    function testA() public override {}
}