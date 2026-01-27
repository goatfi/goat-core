import "adapter_methods.spec";

using MultistrategyHarness as multistrategy;

/////////////////// METHODS ///////////////////////

methods {
    function multistrategy.owner() external returns address envfree;
    function multistrategy.manager() external returns address envfree;
    function multistrategy.guardians(address) external returns bool envfree;
    function multistrategy.asset() external returns address envfree;
    function multistrategy.getStrategyParameters(address) external returns DataTypes.StrategyParams envfree;
    function multistrategy.debtRatio() external returns uint256 envfree;
    function multistrategy.totalAssets() external returns uint256 envfree;
    function multistrategy.totalDebt() external returns uint256 envfree;
    function multistrategy.activeStrategies() external returns uint256 envfree;
    function multistrategy.paused() external returns bool envfree;
    function multistrategy.reentrancyGuardEntered() external returns bool envfree;
    function multistrategy.depositLimit() external returns uint256 envfree;
    
    function convertToAssets(uint256) external returns uint256;
    function multistrategy.maxDeposit(address) external returns uint256;
    function multistrategy.maxWithdraw(address) external returns uint256;

    function multistrategy.strategyReport(uint256,uint256,uint256) external;
    function multistrategy.deposit(uint256,address) external returns uint256;
    function multistrategy.mint(uint256,address) external returns uint256;
    function multistrategy.withdraw(uint256,address,address) external returns uint256;
    function multistrategy.redeem(uint256,address,address) external returns uint256;

    function multistrategy.previewDeposit(uint256) external returns uint256;
    function multistrategy.previewMint(uint256) external returns uint256;
    function multistrategy.previewWithdraw(uint256) external returns uint256;
    function multistrategy.previewRedeem(uint256) external returns uint256;

    // Helpers from Harness
    function withdrawOrderIsValid() external returns bool envfree;
}