import "adapter_methods.spec";

function multistrategyRequirements() {
    require(adapter.multistrategy() == multistrategy, "Multistrategy must match");
}

function vaultRequirements() {
    require(adapter.vault() == vault, "Adapter vault must match");
    require(adapter.asset() == vault.asset(), "Assets must match");
}