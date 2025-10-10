methods {
    function owner() external returns address envfree;
    function manager() external returns address envfree;
    function guardians(address) external returns bool envfree;
    function getStrategyParameters(address) external returns MStrat.StrategyParams envfree;

    function _.multistrategy() external => DISPATCH(optimistic=true)[Adapter._];
}

definition userAllowed(method f) returns bool = 
    f.isView ||
    f.selector == sig:deposit(uint256,address).selector ||
    f.selector == sig:mint(uint256,address).selector ||
    f.selector == sig:withdraw(uint256,address,address).selector ||
    f.selector == sig:redeem(uint256,address,address).selector ||
    f.selector == sig:transfer(address,uint256).selector ||
    f.selector == sig:transferFrom(address,address,uint256).selector ||
    f.selector == sig:approve(address,uint256).selector;


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