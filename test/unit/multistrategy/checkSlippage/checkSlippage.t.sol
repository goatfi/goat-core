// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { MultistrategyHarness_Base_Test } from "../../../shared/MultistrategyHarness_Base.t.sol";
import { Errors } from "src/libraries/Errors.sol";

contract CheckSlippage_Integration_Concrete_Test is MultistrategyHarness_Base_Test {

    modifier whenSlippageLimitIs(uint16 _limit) {
        vm.prank(users.owner); multistrategy.setSlippageLimit(_limit);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EARLY REVERTS WHEN ACTUAL IS ZERO
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_ActualAssetsIsZero()
        external
        whenSlippageLimitIs(100)
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 10000, 100));
        multistrategy.checkSlippage({
            _expectedAssets: 1000 ether,
            _actualAssets: 0,
            _expectedShares: 1000 ether,
            _actualShares: 1000 ether
        });
    }

    function test_RevertWhen_ActualSharesIsZero()
        external
        whenSlippageLimitIs(100)
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 10000, 100));
        multistrategy.checkSlippage({
            _expectedAssets: 1000 ether,
            _actualAssets: 1000 ether,
            _expectedShares: 1000 ether,
            _actualShares: 0
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                               EARLY RETURN TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_CheckSlippage_WhenExpectedAssetsIsZero()
        external
        whenSlippageLimitIs(0)
    {
        // Should not revert even with very high actual exchange rate
        multistrategy.checkSlippage({
            _expectedAssets: 0 ether,
            _actualAssets: 1000 ether,
            _expectedShares: 1000 ether,
            _actualShares: 1000 ether
        });
    }

    function test_CheckSlippage_WhenExpectedSharesIsZero()
        external
        whenSlippageLimitIs(0)
    {
        multistrategy.checkSlippage({
            _expectedAssets: 1000 ether,
            _actualAssets: 1000 ether,
            _expectedShares: 0,
            _actualShares: 1000 ether
        });
    }

    modifier whenBothExpectedGreaterThanZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NO SLIPPAGE SCENARIO
    //////////////////////////////////////////////////////////////////////////*/

    function test_CheckSlippage_NoSlippage()
        external
        whenSlippageLimitIs(0)
        whenBothExpectedGreaterThanZero
    {
        multistrategy.checkSlippage({
            _expectedAssets: 1000 ether,
            _actualAssets: 1000 ether,
            _expectedShares: 1000 ether,
            _actualShares: 1000 ether
        });
    }

    modifier whenExpectedExchangeRateGreaterThanActual() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SLIPPAGE WITHIN LIMITS
    //////////////////////////////////////////////////////////////////////////*/

    function test_CheckSlippage_WithinLimits()
        external
        whenSlippageLimitIs(500) // 5%
        whenBothExpectedGreaterThanZero
        whenExpectedExchangeRateGreaterThanActual
    {
        // Expected rate: 1000/1000 = 1.0 ether per share
        // Actual rate: 970/1000 = 0.97 ether per share
        // Slippage = (1.0 - 0.97) / 1.0 * 10000 = 300 BPS (3%)
        // 3% < 5% limit, should not revert
        multistrategy.checkSlippage({
            _expectedAssets: 1000 ether,
            _actualAssets: 970 ether,
            _expectedShares: 1000 ether,
            _actualShares: 1000 ether
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SLIPPAGE EXCEEDING LIMITS
    //////////////////////////////////////////////////////////////////////////*/

    function test_RevertWhen_SlippageExceedsLimits()
        external
        whenSlippageLimitIs(500) // 5%
        whenBothExpectedGreaterThanZero
        whenExpectedExchangeRateGreaterThanActual
    {
        // Expected rate: 1000/1000 = 1.0 ether per share
        // Actual rate: 900/1000 = 0.9 ether per share
        // Slippage = (1.0 - 0.9) / 1.0 * 10000 = 1000 BPS (10%)
        // 10% > 5% limit, should revert
        vm.expectRevert(abi.encodeWithSelector(Errors.SlippageCheckFailed.selector, 1000, 500));
        multistrategy.checkSlippage({
            _expectedAssets: 1000 ether,
            _actualAssets: 900 ether,
            _expectedShares: 1000 ether,
            _actualShares: 1000 ether
        });
    }
}