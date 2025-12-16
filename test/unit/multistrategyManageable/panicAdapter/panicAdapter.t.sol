// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Multistrategy_Base_Test} from "../../../shared/Multistrategy_Base.t.sol";
import {MockAdapter} from "../../../mocks/MockAdapter.sol";
import {Errors} from "src/libraries/Errors.sol";

contract PanicAdapter_Unit_Concrete_Test is Multistrategy_Base_Test {
    function test_RevertWhen_CallerNotGuardian() external {
        MockAdapter adapter = _createAndAddAdapter(5_000,100 ether, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Errors.Unauthorized.selector, users.bob));
        vm.prank(users.bob); multistrategy.panicAdapter(address(adapter));  
    }

    modifier whenCallerIsGuardian() {
        _;
    }

    function test_RevertWhen_StrategyNotActive() external whenCallerIsGuardian {
        address inactiveStrategy = makeAddr("strategy");

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.StrategyNotActive.selector,
                inactiveStrategy
            )
        );
        vm.prank(users.guardian);
        multistrategy.panicAdapter(inactiveStrategy);
    }

    modifier whenStrategyIsActive() {
        _;
    }

    function test_PanicAdapter()
        external
        whenCallerIsGuardian
        whenStrategyIsActive
    {
        MockAdapter adapter = _createAndAddAdapter(5_000,100 ether, type(uint256).max);
        _userDeposit(users.alice, 1_000 ether);
        vm.prank(adapter.owner()); adapter.requestCredit();
        assertGt(multistrategy.strategyTotalDebt(address(adapter)), 0, "panicAdapter, initial total debt");

        vm.prank(users.guardian); multistrategy.panicAdapter(address(adapter));

        // Assert the debt ratio of the adapter is 0
        assertEq(multistrategy.getStrategyParameters(address(adapter)).debtRatio, 0, "panicAdapter, debt ratio");
        // Assert the total assets of the adapter is 0
        assertEq(adapter.totalAssets(), 0, "panicAdapter, total assets");
        // Assert the total debt of the adapter is 0
        assertEq(multistrategy.strategyTotalDebt(address(adapter)), 0, "panicAdapter, total debt"); 
    }

    modifier whenCallerIsOwner() {
        _;
    }

    function test_PanicAdapter_OwnerCanCallAsGuardian()
        external
        whenStrategyIsActive
        whenCallerIsOwner
    {
        MockAdapter adapter = _createAndAddAdapter(5_000,100 ether, type(uint256).max);
        _userDeposit(users.alice, 1_000 ether); 
        vm.prank(adapter.owner()); adapter.requestCredit();
        assertGt(multistrategy.strategyTotalDebt(address(adapter)), 0, "panicAdapter by owner, initial total debt");

        vm.prank(users.owner); multistrategy.panicAdapter(address(adapter));

        // Assert the debt ratio of the adapter is 0
        assertEq(multistrategy.getStrategyParameters(address(adapter)).debtRatio, 0, "panicAdapter by owner, debt ratio");
        // Assert the total assets of the adapter is 0
        assertEq(adapter.totalAssets(), 0, "panicAdapter by owner, total assets");
        // Assert the total debt of the adapter is 0
        assertEq(multistrategy.strategyTotalDebt(address(adapter)), 0, "panicAdapter by owner, total debt");    
    }
}
