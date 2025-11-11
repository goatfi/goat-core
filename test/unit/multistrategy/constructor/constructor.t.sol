// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Test } from "forge-std/src/Test.sol";
import { Multistrategy } from "src/Multistrategy.sol";
import { MockERC20 } from "../../../mocks/MockERC20.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Constructor_Integration_Concrete_Test is Test {
    MockERC20 asset = new MockERC20("Test Token", "TEST");
    address manager = makeAddr("manager");
    address protocolFeeRecipient;
    string name = "Test Multistrategy";
    string symbol = "TMULT";

    function test_RevertWhen_ProtocolFeeRecipientIsZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        new Multistrategy({
            _asset: address(asset),
            _manager: manager,
            _protocolFeeRecipient: protocolFeeRecipient,
            _name: name,
            _symbol: symbol
        });
    }

    modifier whenProtocolFeeRecipientNotZero() {
        protocolFeeRecipient = makeAddr("feeRecipient");
        _;
    }

    function test_Constructor_Success() external whenProtocolFeeRecipientNotZero {
        Multistrategy multistrategy = new Multistrategy({
            _asset: address(asset),
            _manager: manager,
            _protocolFeeRecipient: protocolFeeRecipient,
            _name: name,
            _symbol: symbol
        });

        assertEq(multistrategy.owner(), address(this), "owner");
        assertEq(multistrategy.manager(), manager, "manager");
        assertEq(multistrategy.protocolFeeRecipient(), protocolFeeRecipient, "protocolFeeRecipient");
        assertEq(multistrategy.performanceFee(), 1000, "performanceFee");
        assertEq(multistrategy.lastReport(), block.timestamp, "lastReport");

        // Assert DECIMALS_OFFSET is calculated correctly (max(0, 18 - asset.decimals()))
        // MockERC20 has 18 decimals by default, so DECIMALS_OFFSET should be 0
        assertEq(multistrategy.DECIMALS_OFFSET(), 0, "DECIMALS_OFFSET");
        uint256 expectedDegradation = uint256(1 ether) / (3 days);
        assertEq(multistrategy.LOCKED_PROFIT_DEGRADATION(), expectedDegradation, "LOCKED_PROFIT_DEGRADATION");
        assertEq(multistrategy.depositLimit(), 0, "depositLimit");
        assertEq(multistrategy.slippageLimit(), 0, "slippageLimit");
        assertEq(multistrategy.debtRatio(), 0, "debtRatio");
        assertEq(multistrategy.totalDebt(), 0, "totalDebt");
        assertEq(multistrategy.activeStrategies(), 0, "activeStrategies");
        assertEq(multistrategy.lockedProfit(), 0, "lockedProfit");
    }
}