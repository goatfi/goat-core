import "../base/multistrategy.spec";

///////////////// PROPERTIES //////////////////////

rule userCannotAccessPrivilegedFunctions(env e, method f, calldataarg args) filtered {f-> !userAllowed(f)}
{
    require(
        e.msg.sender != owner() && 
        e.msg.sender != manager() && 
        !guardians(e.msg.sender) &&
        getStrategyParameters(e.msg.sender).activation == 0,
        "Msg.sender does not have privileged access");

    f@withrevert(e, args);
    assert lastReverted;
}