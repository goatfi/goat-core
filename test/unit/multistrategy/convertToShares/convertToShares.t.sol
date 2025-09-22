// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Multistrategy_Base_Test } from "../../../shared/Multistrategy_Base.t.sol";
import { Multistrategy } from "../../../../src/Multistrategy.sol";
import { MockUSDC } from "../../../mocks/MockUSDC.sol";

contract ConvertToShares_Integration_Concrete_Test is Multistrategy_Base_Test {
    Multistrategy multistrategyLowDecimals;
    MockUSDC usdc;

    uint256 constant DECIMALS = 6;
    uint256 constant OFFSET = 18 - DECIMALS; // 12
    uint256 constant SCALE = 10 ** OFFSET; // 10^12

    uint256 depositAmount = 1000 ether;
    uint256 depositAmountLow = 1000 * 10 ** DECIMALS;

    function test_ConvertToShares_ZeroAmount() external view {
        //Assert that shares for assets is zero when the assets of shares is zero
        uint256 actualShares = multistrategy.convertToShares(0);
        uint256 expectedShares = 0;
        assertEq(actualShares, expectedShares, "convertToShares");
    }

    modifier whenAssetsNotZero() {
        _;
    }

    function test_ConvertToShares_ZeroTotalSupply() 
        external view
        whenAssetsNotZero
    {
        //Assert that shares for assets is zero when the assets of shares is zero
        uint256 actualShares = multistrategy.convertToShares(depositAmount);
        uint256 expectedShares = depositAmount;
        assertEq(actualShares, expectedShares, "convertToShares");
    }

    modifier whenTotalSupplyNotZero() {
        _userDeposit(users.bob, depositAmount);
        _;
    }

    function test_ConvertToShares()
        external
        whenAssetsNotZero
        whenTotalSupplyNotZero
    {   
        uint256 decimalsOffset = uint256(18) - assetDecimals;
        uint256 freeFunds = multistrategy.totalAssets();
        uint256 totalSupply = multistrategy.totalSupply();

        //Assert that shares is the assets multiplied by totalSupply and divided by freeFunds
        uint256 actualShares = multistrategy.convertToShares(depositAmount);
        uint256 expectedShares = Math.mulDiv(depositAmount, totalSupply + 10 ** decimalsOffset, freeFunds + 1, Math.Rounding.Floor);
        assertEq(actualShares, expectedShares, "convertToShares");
    }

    modifier whenFreeFundsNotZeroLowDecimals() {
        _createLowDecimalsMultistrategy();
        _userDepositLowDecimals(users.bob, depositAmountLow);
        _;
    }

    function test_ConvertToShares_LowDecimals()
        external
        whenAssetsNotZero
        whenFreeFundsNotZeroLowDecimals
    {
        uint256 freeFunds = multistrategyLowDecimals.totalAssets();
        uint256 totalSupply = multistrategyLowDecimals.totalSupply();

        // When amount > 0 and freeFunds > 0 and asset decimals < 18: it returns amount multiplied by (totalSupply + 10^(18-decimals)) divided by (freeFunds + 1)
        uint256 actualShares = multistrategyLowDecimals.convertToShares(depositAmountLow);
        uint256 expectedShares = Math.mulDiv(depositAmountLow, totalSupply + SCALE, freeFunds + 1, Math.Rounding.Floor);
        assertEq(actualShares, expectedShares, "convertToShares low decimals");
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