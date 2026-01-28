// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Base_Test } from "./Base.t.sol";
import { MockAdapter } from "../mocks/MockAdapter.sol";
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

    function _createAdapter() internal returns (MockAdapter adapter) {
        adapter = new MockAdapter(users.manager, address(multistrategy));
    }

    function _createAndAddAdapter(uint16 _debtRatio, uint256 _minDebtDelta, uint256 _maxDebtDelta) internal returns (MockAdapter adapter) {
        adapter = new MockAdapter(users.manager, address(multistrategy));
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