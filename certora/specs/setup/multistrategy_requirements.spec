import "multistrategy_methods.spec";

function timestampRequirements(env e) {
    require(e.block.timestamp > 0, "Timestamp cannot be 0");
}

// @notice Scene contracts are hooked
function sceneContractsRequirements() {
    require(adapter.vault() == vault, "Adapter vault must match");
    require(adapter.asset() == vault.asset(), "Assets must match");
    require(multistrategy.asset() == adapter.asset(), "Assets must match");
}

// @notice Address is not one of the contracts
function nonSceneAddressRequirements(address a) {
    require (a != multistrategy, "Address is not Multistrategy");
    require (a != adapter, "Address is not Adapter");
    require (a != asset, "Address is not Asset");
    require (a != vault, "Address is not Vault");
}

function assetToSharesRelationshipRequirements(env e) {
    require(multistrategy.convertToAssets(e, 10^18) >= 1, "Shares must be worth something");
}

function nonPausedRequirements() {
    require (!multistrategy.paused(), "Multistrategy not paused");
    require (!adapter.paused(), "Adapter not paused");
}

function nonReenteredRequirement() {
    require(!multistrategy.reentrancyGuardEntered(), "Multistrategy is not in ENTERED state");
}
