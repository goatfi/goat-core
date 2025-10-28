import "../setup/complete_setup.spec";

rule HLP_PreviewDepositCorrectness(env e, address receiver) {
    nonSceneAddressRequirements(receiver);

    uint256 assets;
    uint256 sharesReported = previewDeposit(e, assets);
    uint256 sharesReceived = deposit(e, assets, receiver);

    assert sharesReported <= sharesReceived;
}

rule HLP_PreviewMintCorrectness(env e, address receiver) {
    nonSceneAddressRequirements(receiver);

    uint256 shares;
    uint256 assetsReported = previewMint(e, shares);
    uint256 assetsPaid = mint(e, shares, receiver);

    assert assetsReported == assetsPaid; //Check the signs
}

rule HLP_PreviewWithdrawCorrectness(env e, address receiver) {
    nonSceneAddressRequirements(receiver);

    uint256 assets;
    uint256 sharesReported = previewWithdraw(e, assets);
    uint256 sharesPaid = withdraw(e, assets, receiver, e.msg.sender);
    assert sharesPaid == sharesReported; //Check the signs
}

rule HLP_PreviewRedeemCorrectness(env e, address receiver) {
    nonSceneAddressRequirements(receiver);

    uint256 shares;
    uint256 assetsReported = previewRedeem(e, shares);
    uint256 assetsReceived = redeem(e, shares, receiver, e.msg.sender);

    assert assetsReported <= assetsReceived;
}   