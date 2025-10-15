/////////////////// METHODS ///////////////////////

methods {
    function owner() external returns address envfree;
    function guardians(address) external returns bool envfree;
}

///////////////// DEFINITIONS /////////////////////

definition canChangeGuardian(method f) returns bool =
    f.selector == sig:enableGuardian(address).selector ||
    f.selector == sig:revokeGuardian(address).selector;

///////////////// PROPERTIES //////////////////////

rule onlyOwnerCanChangeOwner(env e, address newOwner) 
{
    address ownerBefore = owner();
    transferOwnership(e, newOwner);
    address ownerAfter = owner();

    assert ownerBefore != ownerAfter => e.msg.sender == ownerBefore;
}

rule onlyOwnerCanChangeGuardians(env e, method f, calldataarg args, address guardian) filtered {f -> canChangeGuardian(f)}
{  
    bool guardianBefore = guardians(guardian);
    f(e, args);
    bool guardianAfter = guardians(guardian);

    assert guardianBefore != guardianAfter => e.msg.sender == owner();
}