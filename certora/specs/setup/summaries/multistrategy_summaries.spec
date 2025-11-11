import "../adapter_methods.spec";

methods {
    function _.askReport() external => DISPATCH(optimistic=true) [adapter.askReport()];
    function _.availableLiquidity() external => DISPATCH(optimistic=true) [adapter.availableLiquidity()];
    function _.currentPnL() external => DISPATCH(optimistic=true) [adapter.currentPnL()];
    function _.multistrategy() external => DISPATCH(optimistic=true) [adapter.multistrategy()];
    function _.totalAssets() external => DISPATCH(optimistic=true) [adapter.totalAssets()];
    function _.withdraw(uint256) external => DISPATCH(optimistic=true) [adapter.withdraw(uint256)];
}