import "../setup/complete_setup.spec";

///////////////// PROPERTIES //////////////////////

rule userCannotHaveAccess(env e, method f, calldataarg args) filtered {f-> !f.isView}
{
    require(
        e.msg.sender != owner() && 
        e.msg.sender != multistrategy() &&
        !guardians(e.msg.sender),
        "Msg.sender does not have privileged access");

    f@withrevert(e, args);
    assert lastReverted;
}

rule totalDebtCanOnlyIncreaseWithRequestCredit(env e, method f, calldataarg args) filtered {f-> !userAllowed(f)}
{
    mathint previousDebt = adapter.totalDebt();
    f(e,args);
    mathint currentDebt = adapter.totalDebt();

    assert currentDebt < previousDebt => 
                                        f.selector == sig:sendReport(uint256).selector ||
                                        f.selector == sig:askReport().selector ||
                                        f.selector == sig:sendReportPanicked().selector;
}

rule totalDebtCanOnlyDecreaseWithSendReport(env e, method f, calldataarg args) filtered {f-> !userAllowed(f)} 
{
    mathint previousDebt = adapter.totalDebt();

    f(e,args);

    mathint currentDebt = adapter.totalDebt();

    assert currentDebt > previousDebt => f.selector == sig:requestCredit().selector;
}