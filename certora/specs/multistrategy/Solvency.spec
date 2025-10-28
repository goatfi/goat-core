import "../setup/complete_setup.spec";

// A user should not be able to deposit more than maxDeposit
rule maxDeposit_Reverts(env e, uint256 amount, address receiver) {
    SafeAssumptions(e);

    uint256 maxDeposit = maxDeposit(e, receiver);
    require(amount > maxDeposit, "User deposits more than what is allowed");

    uint256 deposited = deposit@withrevert(e, amount, receiver);
    assert lastReverted;
}

// A user should always be able to withdraw up to maxWithdraw()
rule maxWithdraw_Liquidity(env e, uint256 amount, address receiver) {
    require(receiver != 0 && receiver != multistrategy, "Cannot withdraw to an invalid strategy");
    require(multistrategy.withdrawOrderIsValid(), "Withdraw queue must be valid");

    SafeAssumptions(e);

    uint256 maxWithdraw = maxWithdraw(e, e.msg.sender);
    require(amount <= maxWithdraw && amount > 0, "Amount is less or equal to maxWithdaw");

    uint256 withdrawn = withdraw@withrevert(e, amount, receiver, e.msg.sender);
    assert !lastReverted;
}

// A user should not be able to withdraw more than maxWithdraaw()
/*rule maxWithdraw_Reverts(env e, uint256 amount, address receiver) {
    SafeAssumptions(e);

    uint256 maxWithdraw = maxWithdraw(e, receiver);
    require(amount > maxWithdraw, "User withdraws more than maxWithdaw");

    uint256 withdrawn = withdraw@withrevert(e, amount, receiver, receiver);
    assert lastReverted;
}*/