rule MethodsVacuityCheck(env e, method f, calldataarg args) {
    f(e, args);
    assert false;
}