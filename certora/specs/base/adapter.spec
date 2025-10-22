/////////////////// METHODS ///////////////////////

methods {
    function owner() external returns address envfree;
    function manager() external returns address envfree;
    function guardians(address) external returns bool envfree;
    function getStrategyParameters(address) external returns DataTypes.StrategyParams envfree;
    function multistrategy() external returns address envfree;
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

definition canChangeGuardian(method f) returns bool =
    f.selector == sig:enableGuardian(address).selector ||
    f.selector == sig:revokeGuardian(address).selector;