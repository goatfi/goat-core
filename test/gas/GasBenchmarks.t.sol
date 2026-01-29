// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Multistrategy_Base_Test } from "../shared/Multistrategy_Base.t.sol";
import { console } from "forge-std/src/console.sol";
import { MockAdapter } from "../mocks/MockAdapter.sol";

contract GasBenchmarks is Multistrategy_Base_Test {
    MockAdapter public adapter;
    
    // Override setUp to initialize the test environment properly
    function setUp() public override {
        super.setUp();
        adapter = _createAdapter();
    }

    function test_Benchmark_Deposit_FirstTime() public {
        uint256 amount = 1000 * 1 ether;
        
        // Ensure Alice has tokens
        dai.mint(users.alice, amount * 2);
        
        vm.startPrank(users.alice);
        dai.approve(address(multistrategy), type(uint256).max);

        vm.startSnapshotGas("Deposit_FirstTime");
        multistrategy.deposit(amount, users.alice);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }

    function test_Benchmark_Deposit_Subsequent() public {
        uint256 amount = 1000 * 1 ether;
        _userDeposit(users.alice, amount); // First deposit helper
        
        // Prepare for second deposit
        dai.mint(users.alice, amount);
        vm.startPrank(users.alice);
        dai.approve(address(multistrategy), amount);

        vm.startSnapshotGas("Deposit_Subsequent");
        multistrategy.deposit(amount, users.alice);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }

    function test_Benchmark_Withdraw_FromLiquidity() public {
        uint256 amount = 1000 * 1 ether;
        _userDeposit(users.alice, amount);
        
        vm.startPrank(users.alice);
        vm.startSnapshotGas("Withdraw_FromLiquidity");
        multistrategy.withdraw(amount, users.alice, users.alice);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }

    function test_Benchmark_AddStrategy() public {
        MockAdapter newAdapter = new MockAdapter(users.manager, address(multistrategy));
        uint16 debtRatio = 5000; // 50%
        
        vm.startPrank(users.owner);
        vm.startSnapshotGas("AddStrategy");
        multistrategy.addStrategy(address(newAdapter), debtRatio, 0, 10000 * 1 ether);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }
    
    function test_Benchmark_AddSecondStrategy() public {
        // Setup initial strategy
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 5000, 0, type(uint256).max);
        
        MockAdapter secondAdapter = new MockAdapter(users.manager, address(multistrategy));

        vm.startPrank(users.owner);
        vm.startSnapshotGas("AddSecondStrategy");
        multistrategy.addStrategy(address(secondAdapter), 4000, 0, type(uint256).max);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }

    function test_Benchmark_Withdraw_FromAdapter() public {
        // 1. Add Strategy
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 10000, 0, type(uint256).max);

        // 2. Deposit
        uint256 amount = 1000 * 1 ether;
        _userDeposit(users.alice, amount);

        // 3. Adapter requests credit
        vm.prank(users.manager);
        adapter.requestCredit();
        
        // 5. Benchmark Withdraw
        vm.startPrank(users.alice);
        vm.startSnapshotGas("Withdraw_FromAdapter");
        multistrategy.withdraw(amount, users.alice, users.alice);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }
    
    function test_Benchmark_Withdraw_Cascading() public {
        // 1. Setup two strategies
        MockAdapter adapter2 = new MockAdapter(users.manager, address(multistrategy));
        
        vm.startPrank(users.owner);
        multistrategy.addStrategy(address(adapter), 5000, 0, type(uint256).max); // 50%
        multistrategy.addStrategy(address(adapter2), 5000, 0, type(uint256).max); // 50%
        vm.stopPrank();

        // 2. Deposit large amount
        uint256 amount = 100_000 * 1 ether;
        _userDeposit(users.alice, amount);

        // 3. Both adapters request credit
        vm.startPrank(users.manager);
        adapter.requestCredit();
        adapter2.requestCredit();
        vm.stopPrank();
        
        // Ensure both have funds
        assertGt(dai.balanceOf(address(adapter.vault())), 0);
        assertGt(dai.balanceOf(address(adapter2.vault())), 0);

        // 4. Benchmark Withdraw (amount > single adapter liquidity)
        vm.startPrank(users.alice);
        vm.startSnapshotGas("Withdraw_Cascading");
        // Withdraw 75% of total, forcing pull from both
        multistrategy.withdraw(amount * 75 / 100, users.alice, users.alice);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }

    function test_Benchmark_StrategyReport_NoActivity() public {
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 10000, 0, type(uint256).max);

        _userDeposit(users.alice, 1000 * 1 ether);

        vm.prank(users.manager);
        adapter.requestCredit();

        // Benchmark report
        vm.prank(users.manager);
        vm.startSnapshotGas("StrategyReport_NoActivity");
        adapter.sendReport(0);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
    }

    function test_Benchmark_StrategyReport_Gain() public {
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 10000, 0, type(uint256).max);

        _userDeposit(users.alice, 1000 * 1 ether);

        vm.prank(users.manager);
        adapter.requestCredit();

        // Simulate Gain
        adapter.earn(100 * 1 ether);

        // Benchmark report
        vm.prank(users.manager);
        vm.startSnapshotGas("StrategyReport_Gain");
        adapter.sendReport(0);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
    }

    function test_Benchmark_StrategyReport_Loss() public {
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 10000, 0, type(uint256).max);

        _userDeposit(users.alice, 1000 * 1 ether);

        vm.prank(users.manager);
        adapter.requestCredit();

        // Simulate Loss
        adapter.lose(100 * 1 ether);

        // Benchmark report
        vm.prank(users.manager);
        vm.startSnapshotGas("StrategyReport_Loss");
        adapter.sendReport(0);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
    }

    function test_Benchmark_StrategyReport_RepayWithGain() public {
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 10000, 0, type(uint256).max);

        _userDeposit(users.alice, 1000 * 1 ether);

        vm.prank(users.manager); adapter.requestCredit();
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(adapter), 0);

        // Simulate Gain
        adapter.earn(100 * 1 ether);

        // Benchmark report
        vm.prank(users.manager);
        vm.startSnapshotGas("StrategyReport_RepayWithGain");
        adapter.sendReport(type(uint256).max);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
    }

    function test_Benchmark_StrategyReport_RepayWithLoss() public {
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 10000, 0, type(uint256).max);

        _userDeposit(users.alice, 1000 * 1 ether);

        vm.prank(users.manager); adapter.requestCredit();
        vm.prank(users.manager); multistrategy.setStrategyDebtRatio(address(adapter), 0);

        // Simulate Loss
        adapter.lose(100 * 1 ether);

        // Benchmark report
        vm.prank(users.manager);
        vm.startSnapshotGas("StrategyReport_RepayWithLoss");
        adapter.sendReport(type(uint256).max);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
    }
    
    function test_Benchmark_Manager_SetDebtRatio() public {
        vm.prank(users.owner);
        multistrategy.addStrategy(address(adapter), 5000, 0, type(uint256).max);

        _userDeposit(users.alice, 1000 * 1 ether);

        vm.prank(users.manager);
        adapter.requestCredit();

        // Benchmark set debt ratio
        vm.startPrank(users.manager);
        vm.startSnapshotGas("SetStrategyDebtRatio");
        multistrategy.setStrategyDebtRatio(address(adapter), 6000);
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }

    function test_Benchmark_Rebalance() public {
        // 1. Setup two strategies
        MockAdapter adapter2 = new MockAdapter(users.manager, address(multistrategy));
        
        vm.startPrank(users.owner);
        multistrategy.addStrategy(address(adapter), 10_000, 0, type(uint256).max); // 100%
        multistrategy.addStrategy(address(adapter2), 0, 0, type(uint256).max); // 0%
        vm.stopPrank();

        // 2. Deposit
        uint256 amount = 100_000 * 1 ether;
        _userDeposit(users.alice, amount);

        // 3. Request credit
        vm.prank(users.manager); adapter.requestCredit();
        
        // Ensure both have funds
        assertGt(dai.balanceOf(address(adapter.vault())), 0);

        // 4. Benchmark Rebalance
        vm.startPrank(users.manager);
        vm.startSnapshotGas("Rebalance");
        multistrategy.setStrategyDebtRatio(address(adapter), 0);
        multistrategy.setStrategyDebtRatio(address(adapter2), 10_000);
        adapter.sendReport(0);
        adapter2.requestCredit();
        uint256 gasUsed = vm.stopSnapshotGas();
        console.log(string.concat("Gas Used: ", vm.toString(gasUsed)));
        vm.stopPrank();
    }
}
