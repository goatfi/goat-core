using Utils as utils;

/////////////////// METHODS ///////////////////////

methods {
    function debtRatio() external returns uint256 envfree;
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
}

///////////////// DEFINITIONS /////////////////////

definition canChangeWithdrawOrder(method f) returns bool = 
    f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
    f.selector == sig:removeStrategy(address).selector ||
    f.selector == sig:setWithdrawOrder(address[]).selector;

definition canChangeDebtRatio(method f) returns bool =
    f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
    f.selector == sig:setStrategyDebtRatio(address,uint256).selector;

///////////////// GHOSTS & HOOKS //////////////////

persistent ghost mapping(address => mathint) debtRatios {
    axiom forall address s. debtRatios[s] <= 10000;
    init_state axiom forall address s. debtRatios[s] == 0;
}

hook Sstore strategies[KEY address s].debtRatio uint256 new_debtRatio {
    debtRatios[s] = new_debtRatio;
}

hook Sload uint256 debtRatio strategies[KEY address s].debtRatio {
    require(debtRatios[s] == debtRatio, "Keep the ghost hooked");
}

hook Sload uint256 activation strategies[KEY address s].activation {
    if(activation == 0) require(debtRatios[s] == 0, "A non active strategy cannot have >0 debt ratio");
}

///////////////// PROPERTIES //////////////////////

rule debtRatioConstantRelationship(env e, method f, calldataarg args) filtered {f-> canChangeDebtRatio(f)}
{ 
    require(debtRatio() == (usum address s. debtRatios[s]) && debtRatio() <= 10000, "DebtRatio start as a valid state");

    f(e,args);

    assert debtRatio() == (usum address s. debtRatios[s]) && debtRatio() <= 10000;
}

rule withdrawOrderStateIsValid(env e, method f, calldataarg args) filtered {f -> canChangeWithdrawOrder(f)}
{
    require(utils.withdrawOrderIsValid(getWithdrawOrder()), "Starting withdraw order state must be valid");
    require(activeStrategies() == utils.nonZeroStrategies(getWithdrawOrder()), "Starting activeStrategies state must equal to non-zero strategies");

    f(e, args);

    assert utils.withdrawOrderIsValid(getWithdrawOrder());
}