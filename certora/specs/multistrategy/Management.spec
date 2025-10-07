using Utils as utils;

methods {
    function debtRatio() external returns uint256 envfree;
    function getWithdrawOrder() external returns address[] envfree;
    function activeStrategies() external returns uint8 envfree;
    function getStrategyParameters(address) external returns 
    function utils.withdrawOrderIsValid(address[]) external returns bool envfree;
    function utils.nonZeroStrategies(address[]) external returns uint256 envfree;

    function _.multistrategy() external => DISPATCH(optimistic=true)[MockStrategyAdapter._];
}

ghost mathint sum_of_debtRatios {
    init_state axiom sum_of_debtRatios == 0;
}

hook Sstore strategies[KEY address s].debtRatio uint256 new_value (uint256 old_value) {
    sum_of_debtRatios = sum_of_debtRatios + new_value - old_value;
} 

rule debtRatioConstantRelationship(env e, method f, calldataarg args) 
filtered {
    f -> f.selector == sig:setStrategyDebtRatio(address,uint256).selector ||
        f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
        f.selector == sig:removeStrategy(address).selector 
}
{   
    require forall address s. strategies[s].debtRatio == 0;
    require(debtRatio() == sum_of_debtRatios, "DebtRatio start as a valid state");

    f(e, args);

    assert debtRatio() == sum_of_debtRatios;
}

rule setStrategyDebtRatioMaintainsRelationship(env e, address strategy, uint256 newDebtRatio) 
{
    mathint multiDebtRatioBefore = debtRatio();
    mathint adaptersDebtRatioBefore = sum_of_debtRatios;

    setStrategyDebtRatio(e, strategy, newDebtRatio);

    mathint multiDebtRatioAfter = debtRatio();
    mathint adaptersDebtRatioAfter = sum_of_debtRatios;

    assert multiDebtRatioBefore - adaptersDebtRatioBefore == multiDebtRatioAfter - adaptersDebtRatioAfter;
}

rule addStrategyCannotReduceDebtRatio(env e, address strategy, uint256 debtRatio, uint256 minDelta, uint256 maxDelta) 
{
    mathint multiDebtRatioBefore = debtRatio();

    addStrategy(e, strategy, debtRatio, minDelta, maxDelta);

    mathint multiDebtRatioAfter = debtRatio();

    assert multiDebtRatioAfter >= multiDebtRatioBefore;
}

rule removeStrategyCannotChangeDebtRatio(env e, address strategy) {
    mathint multiDebtRatioBefore = debtRatio();

    removeStrategy(e, strategy);

    mathint multiDebtRatioAfter = debtRatio();

    assert multiDebtRatioAfter == multiDebtRatioBefore;
}

rule withdrawOrderStateIsValid(env e, method f, calldataarg args) 
filtered {
    f -> f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
        f.selector == sig:removeStrategy(address).selector ||
        f.selector == sig:setWithdrawOrder(address[]).selector
}
{
    require(utils.withdrawOrderIsValid(getWithdrawOrder()), "Starting withdraw order state must be valid");
    require(activeStrategies() == utils.nonZeroStrategies(getWithdrawOrder()), "Starting activeStrategies state must equal to non-zero strategies");

    f(e, args);

    assert utils.withdrawOrderIsValid(getWithdrawOrder());
}