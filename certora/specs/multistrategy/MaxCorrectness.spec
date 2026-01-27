import "../setup/complete_setup.spec";

rule maxMint_respects_deposit_limit(env e, address receiver) {
    uint256 limit = depositLimit();
    require(limit > 0, "Deposit limit is 0");
    uint256 currentAssets = totalAssets();

    uint256 maxShares = maxMint(e, receiver);
    
    // Check the asset equivalent of the max shares allowed
    uint256 assetEquivalent = convertToAssets(e, maxShares);

    if (currentAssets < limit) {
        mathint available = limit - currentAssets;
        assert assetEquivalent <= available, "maxMint allows minting shares worth more than the remaining deposit limit";
    } else {
        assert maxShares == 0, "maxMint should be 0 when deposit limit is reached";
    }
}

rule maxMint_zero_when_maxDepositZero(env e, address receiver) {
    require(maxDeposit(e, receiver) == 0, "maxDeposit is not 0");
    assert maxMint(e, receiver) == 0, "maxMint should be 0 when maxDeposit is 0";
}
