using AdapterHarness as adapter;
using AssetHarness as asset;
using VaultHarness as vault;

/////////////////// METHODS ///////////////////////

methods {
    function adapter.owner() external returns address envfree;
    function adapter.multistrategy() external returns address envfree;
    function adapter.totalAssets() external returns uint256 envfree;
    function adapter.totalDebt() external returns uint256 envfree;
    function adapter.vault() external returns address envfree;
    function adapter.asset() external returns address envfree;
    function adapter.currentGain() external returns uint256 envfree;
    function adapter.currentLoss() external returns uint256 envfree;

    function vault.asset() external returns address envfree;
}