import "../setup/complete_setup.spec";

///////////////// PROPERTIES //////////////////////

rule debtRatioConstantRelationship(env e, method f, calldataarg args) filtered {f-> canChangeDebtRatio(f)}
{ 
    require(multistrategy.debtRatio() == (usum address s. debtRatios[s]) && multistrategy.debtRatio() <= 10000, "DebtRatio start as a valid state");

    f(e,args);

    assert multistrategy.debtRatio() == (usum address s. debtRatios[s]) && multistrategy.debtRatio() <= 10000;
}

rule withdrawOrderStateIsValid(env e, method f, calldataarg args) filtered {f -> canChangeWithdrawOrder(f)}
{
    require(e.block.timestamp > 0, "Timestamp cannot be 0");
    require(withdrawOrderIsValid(), "Starting withdraw order state must be valid");

    f(e, args);

    assert withdrawOrderIsValid();
}

rule totalDebtConstantRelationship(env e, method f, calldataarg args) filtered {f-> canChangeDebt(f)}
{
    require(multistrategy.totalDebt() == (usum address s. debts[s]), "Total Debt start as a valid state");

    f(e, args);

    assert multistrategy.totalDebt() == (usum address s. debts[s]);
}