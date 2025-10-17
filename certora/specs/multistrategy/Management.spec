import "../base/multistrategy.spec";

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

rule totalDebtConstantRelationship(env e, method f, calldataarg args) filtered {f-> canChangeDebt(f)}
{
    require(totalDebt() == (usum address s. debts[s]), "Total Debt start as a valid state");

    f(e, args);

    assert totalDebt() == (usum address s. debts[s]);
}