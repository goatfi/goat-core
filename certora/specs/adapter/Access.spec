methods {
    function owner() external returns address envfree;
    function guardians(address) external returns bool envfree;
    function multistrategy() external returns address envfree;
}

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