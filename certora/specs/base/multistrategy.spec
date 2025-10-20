using Utils as utils;

using AssetHarness as asset;
using AdapterHarness as adapter;
using VaultHarness as vault;

/////////////////// METHODS ///////////////////////

methods {
    function owner() external returns address envfree;
    function manager() external returns address envfree;
    function guardians(address) external returns bool envfree;
    function getStrategyParameters(address) external returns DataTypes.StrategyParams envfree;
    function debtRatio() external returns uint256 envfree;
    function totalDebt() external returns uint256 envfree;
    function getWithdrawOrder() external returns address[] envfree;
    function activeStrategies() external returns uint8 envfree;
    function utils.withdrawOrderIsValid(address[]) external returns bool envfree;
    function utils.nonZeroStrategies(address[]) external returns uint256 envfree;

    function _.askReport() external => DISPATCH(optimistic=true) [AdapterHarness._];
    function _.availableLiquidity() external => DISPATCH(optimistic=true) [AdapterHarness._];
    function _.currentPnL() external => DISPATCH(optimistic=true) [AdapterHarness._];
    function _.multistrategy() external => DISPATCH(optimistic=true) [AdapterHarness._];
    function _.totalAssets() external => DISPATCH(optimistic=true) [AdapterHarness._];
    function _.withdraw(uint256) external => DISPATCH(optimistic=true) [AdapterHarness._];
    function Math.mulDiv(uint256 x, uint256 y, uint256 denominator) internal returns uint256 => NONDET;
    function Math.mulDiv(uint256 x, uint256 y, uint256 denominator, Math.Rounding rounding) internal returns (uint256) => NONDET;
}

///////////////// DEFINITIONS /////////////////////

definition userAllowed(method f) returns bool = 
    f.isView ||
    f.selector == sig:deposit(uint256,address).selector ||
    f.selector == sig:mint(uint256,address).selector ||
    f.selector == sig:withdraw(uint256,address,address).selector ||
    f.selector == sig:redeem(uint256,address,address).selector ||
    f.selector == sig:transfer(address,uint256).selector ||
    f.selector == sig:transferFrom(address,address,uint256).selector ||
    f.selector == sig:approve(address,uint256).selector;

definition canChangeWithdrawOrder(method f) returns bool = 
    f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
    f.selector == sig:removeStrategy(address).selector ||
    f.selector == sig:setWithdrawOrder(address[]).selector;

definition canChangeDebtRatio(method f) returns bool =
    f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
    f.selector == sig:setStrategyDebtRatio(address,uint256).selector;

definition canChangeDebt(method f) returns bool =
    f.selector == sig:requestCredit().selector ||
    f.selector == sig:strategyReport(uint256,uint256,uint256).selector ||
    f.selector == sig:withdraw(uint256,address,address).selector ||
    f.selector == sig:redeem(uint256,address,address).selector;

///////////////// GHOSTS & HOOKS //////////////////

persistent ghost mapping(address => mathint) debtRatios {
    axiom forall address s. debtRatios[s] <= 10000;
    init_state axiom forall address s. debtRatios[s] == 0;
}

persistent ghost mapping(address => mathint) debts {
    init_state axiom forall address s. debts[s] == 0;
}

hook Sstore strategies[KEY address s].debtRatio uint256 new_debtRatio {
    debtRatios[s] = new_debtRatio;
}

hook Sstore strategies[KEY address s].totalDebt uint256 new_debt {
    debts[s] = new_debt;
}

hook Sload uint256 debtRatio strategies[KEY address s].debtRatio {
    require(debtRatios[s] == debtRatio, "Keep the ghost hooked");
}

hook Sload uint256 debt strategies[KEY address s].totalDebt {
    require(debts[s] == debt, "Keep the ghost hooked");
}

hook Sload uint256 activation strategies[KEY address s].activation {
    if(activation == 0) require(debtRatios[s] == 0, "A non active strategy cannot have >0 debt ratio");
}