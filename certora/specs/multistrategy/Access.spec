import "../setup/complete_setup.spec";

///////////////// PROPERTIES //////////////////////

rule userCannotAccessPrivilegedFunctions(env e, method f, calldataarg args) filtered {f-> !userAllowed(f)}
{
    require(
        e.msg.sender != multistrategy.owner() && 
        e.msg.sender != multistrategy.manager() && 
        !multistrategy.guardians(e.msg.sender) &&
        multistrategy.getStrategyParameters(e.msg.sender).lastReport == 0,
        "Msg.sender does not have privileged access");

    f@withrevert(e, args);
    assert lastReverted;
}