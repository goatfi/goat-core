// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Multistrategy } from "../../../../src/Multistrategy.sol";
import { MockUSDC } from "../../../mocks/MockUSDC.sol";

contract ConvertToAssets_Integration_Concrete_Test is Multistrategy_Base_Test {
    Multistrategy multistrategyLowDecimals;
    MockUSDC usdc;

    uint256 constant DECIMALS = 6;
    uint256 constant OFFSET = 18 - DECIMALS; // 12
    uint256 constant SCALE = 10 ** OFFSET; // 10^12

    uint256 shares = 1000 ether;

    function test_ConvertToAssets_ZeroTotalSupply() external view {
        // Assert share value is zero when totalSupply is 0
        uint256 actualAssets = multistrategy.convertToAssets(shares);
        uint256 expectedAssets = shares;
        assertEq(actualAssets, expectedAssets, "convertToAssets");
    }

    modifier whenTotalSupplyNotZero() {
        _userDeposit(users.bob, 1000 ether);
        _;
    }

    function test_ConvertToAssets_ZeroSharesAmount() 
        external
        whenTotalSupplyNotZero
    {
        uint256 actualAssets = multistrategy.convertToAssets(0);
        uint256 expectedAssets = 0;
        assertEq(actualAssets, expectedAssets, "convertToAssets");
    }

    modifier whenSharesAmountNotZero() {
        _;
    }

    function test_ConvertToAssets()
        external
        whenTotalSupplyNotZero
        whenSharesAmountNotZero
    {
        uint256 totalAssets = multistrategy.totalAssets();
        uint256 totalSupply = multistrategy.totalSupply();

        // Assert share value is the amount of shares multiplied by freeFunds, divided by totalSupply
        uint256 actualAssets = multistrategy.convertToAssets(shares);
        uint256 expectedAssets = Math.mulDiv(shares, totalAssets + 1, totalSupply + 1, Math.Rounding.Floor);
        assertEq(actualAssets, expectedAssets, "convertToAssets");
    }

    modifier whenTotalSupplyNotZeroLowDecimals() {
        _createLowDecimalsMultistrategy();
        _userDepositLowDecimals(users.bob, 1000 * 10 ** DECIMALS);
        _;
    }

    function test_ConvertToAssets_LowDecimals()
        external
        whenTotalSupplyNotZeroLowDecimals
        whenSharesAmountNotZero
    {
        uint256 freeFunds = multistrategyLowDecimals.totalAssets() - multistrategyLowDecimals.lockedProfit();
        uint256 totalSupply = multistrategyLowDecimals.totalSupply();

        // When totalSupply > 0 and shares > 0: it should return shares multiplied by freeFunds divided by (totalSupply + 10^(18 - decimals))
        uint256 actualAssets = multistrategyLowDecimals.convertToAssets(shares);
        uint256 expectedAssets = Math.mulDiv(shares, freeFunds + 1, totalSupply + SCALE, Math.Rounding.Floor);
        assertEq(actualAssets, expectedAssets, "convertToAssets low decimals");
    }

    // HELPER FUNCTIONS
    function _createLowDecimalsMultistrategy() internal {
        usdc = new MockUSDC();
        vm.label({ account: address(usdc), newLabel: "USDC" });

        multistrategyLowDecimals = new Multistrategy({
            _asset: address(usdc),
            _manager: users.manager,
            _protocolFeeRecipient: users.feeRecipient,
            _name: "Goat USDC",
            _symbol: "GUSDC"
        });

        multistrategyLowDecimals.enableGuardian(users.guardian);
        multistrategyLowDecimals.setDepositLimit(100_000 * 10 ** usdc.decimals());
        multistrategyLowDecimals.setPerformanceFee(1000);
        multistrategyLowDecimals.transferOwnership(users.owner);

        vm.label({ account: address(multistrategyLowDecimals), newLabel: "MultistrategyLowDecimals" });
    }

    function _userDepositLowDecimals(address _user, uint256 _amount) internal {
        usdc.mint(_user, _amount);

        vm.prank(_user); usdc.approve(address(multistrategyLowDecimals), _amount);
        vm.prank(_user); multistrategyLowDecimals.deposit(_amount, _user);
    }
}