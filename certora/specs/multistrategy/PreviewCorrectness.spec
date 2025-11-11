import "../setup/complete_setup.spec";

rule HLP_PreviewDepositCorrectness(env e) {
    completeSetupForEnv(e);

    uint256 assets;
    uint256 sharesReported = previewDeposit(e, assets);
    uint256 sharesReceived = deposit(e, assets, e.msg.sender);

    assert sharesReported == sharesReceived;
}

rule HLP_PreviewMintCorrectness(env e) {
    completeSetupForEnv(e);

    uint256 shares;
    uint256 assetsReported = previewMint(e, shares);
    uint256 assetsPaid = mint(e, shares, e.msg.sender);

    assert assetsReported == assetsPaid;
}

rule HLP_PreviewWithdrawCorrectness(env e) {
    completeSetupForEnv(e);

    uint256 assets;
    uint256 sharesReported = previewWithdraw(e, assets);
    uint256 sharesPaid = withdraw(e, assets, e.msg.sender, e.msg.sender);
    assert sharesPaid <= sharesReported;
}

rule HLP_PreviewRedeemCorrectness(env e) {
    completeSetupForEnv(e);

    uint256 shares;
    uint256 assetsReported = previewRedeem(e, shares);
    uint256 assetsReceived = redeem(e, shares, e.msg.sender, e.msg.sender);

    assert assetsReceived >= assetsReported;
}   