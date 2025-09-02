// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Test } from "forge-std/src/Test.sol";
import { Multistrategy } from "src/Multistrategy.sol";
import { MockERC20 } from "../../../mocks/MockERC20.sol";
import { Errors } from "src/libraries/Errors.sol";

contract Constructor_Integration_Concrete_Test is Test {

    function test_RevertWhen_ProtocolFeeRecipientIsZeroAddress() external {
        MockERC20 asset = new MockERC20("Test Token", "TEST");
        address manager = makeAddr("manager");
        address protocolFeeRecipient = address(0);
        string memory name = "Test Multistrategy";
        string memory symbol = "TMULT";

        // Expect revert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        new Multistrategy({
            _asset: address(asset),
            _manager: manager,
            _protocolFeeRecipient: protocolFeeRecipient,
            _name: name,
            _symbol: symbol
        });
    }

    function test_Constructor_Success() external {
        MockERC20 asset = new MockERC20("Test Token", "TEST");
        address manager = makeAddr("manager");
        address protocolFeeRecipient = makeAddr("feeRecipient");
        string memory name = "Test Multistrategy";
        string memory symbol = "TMULT";

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

        // Assert withdrawOrder is initialized as array of 10 addresses, all zero
        address[] memory withdrawOrder = multistrategy.getWithdrawOrder();
        assertEq(withdrawOrder.length, 10, "withdrawOrder length");
        for (uint8 i = 0; i < 10; i++) {
            assertEq(withdrawOrder[i], address(0), "withdrawOrder[i]");
        }

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
        assertEq(multistrategy.retired(), false, "retired");
        assertEq(multistrategy.lockedProfit(), 0, "lockedProfit");
    }
}