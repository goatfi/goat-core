import "../base/adapter.spec";

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