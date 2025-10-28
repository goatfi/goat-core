import "../setup/complete_setup.spec";

///////////////// PROPERTIES //////////////////////

rule onlyOwnerCanChangeOwner(env e, address newOwner) 
{
    address ownerBefore = adapter.owner();
    adapter.transferOwnership(e, newOwner);
    address ownerAfter = adapter.owner();

    assert ownerBefore != ownerAfter => e.msg.sender == ownerBefore;
}

rule onlyOwnerCanChangeGuardians(env e, method f, calldataarg args, address guardian) filtered {f -> canChangeGuardian(f)}
{  
    bool guardianBefore = adapter.guardians(guardian);
    f(e, args);
    bool guardianAfter = adapter.guardians(guardian);

    assert guardianBefore != guardianAfter => e.msg.sender == owner();
}