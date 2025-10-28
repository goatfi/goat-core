import "../setup/complete_setup.spec";


///////////////// PROPERTIES //////////////////////

rule onlyOwnerCanChangeOwner(env e, address newOwner) 
{
    address ownerBefore = owner();
    transferOwnership(e, newOwner);
    address ownerAfter = owner();

    assert ownerBefore != ownerAfter => e.msg.sender == ownerBefore;
}

rule onlyOwnerCanChangeManager(env e, address newManager) 
{
    address managerBefore = manager();
    setManager(e, newManager);
    address managerAfter = manager();

    assert managerBefore != managerAfter => e.msg.sender == owner();
}

rule onlyOwnerCanChangeGuardians(env e, method f, calldataarg args, address guardian) filtered {f -> canChangeGuardian(f)}
{  
    bool guardianBefore = guardians(guardian);
    f(e, args);
    bool guardianAfter = guardians(guardian);

    assert guardianBefore != guardianAfter => e.msg.sender == owner();
}