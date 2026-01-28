![Core](https://apricot-many-flamingo-613.mypinata.cloud/ipfs/bafkreien2vagdlnouzxop3r72f5ridnuy67scxtdkgwpxh6hsmqitoknc4)
# Goat Core Contracts

This repository contains the the codebase for the core infrastructure of Goat Multistrategy contracts, built with Foundry. <br>
It also contains the spec and configuration files used to formaly verify the codebase with Certora.

[![codecov](https://codecov.io/gh/goatfi/goat-core/graph/badge.svg?token=LNVEJLRAH1)](https://codecov.io/gh/goatfi/goat-core)

## Table of Contents

- [Goat Core Contracts](#goat-core-contracts)
  - [Installing Certora](#installing-certora)
  - [Math Operations Analysis](#math-operations-analysis)


### Installing Certora

To install the Certora CLI using a Python virtual environment, follow these steps:

1. Create a virtual environment:
   ```bash
   python3 -m venv venv
   ```

2. Activate the virtual environment:
   ```bash
   source venv/bin/activate
   ```

3. Install the Certora CLI:
   ```bash
   pip3 install certora-cli
   ```
4. Set the Certora access key in your `.zshenv` file:
    ```
    export CERTORAKEY=<personal_access_key>
    ```

After installation, you can use Certora CLI commands within the activated virtual environment.

To exit the the virtual environment when done:
   ```bash
   deactivate
   ```

### Math Operations Analysis

This section lists the usage of the `.mulDiv` library function in `src/abstracts/Adapter.sol` and `src/Multistrategy.sol`.

#### `src/abstracts/Adapter.sol`

| Line | Function Name | Rounding Direction | Reason |
| :--- | :--- | :--- | :--- |
| 194 | `_tryWithdraw` | Ceil | Rounding up the validation threshold guards against excessive slippage |

#### `src/Multistrategy.sol`

| Line | Function Name | Rounding Direction | Reason |
| :--- | :--- | :--- | :--- |
| 104 | `previewWithdraw` | Ceil | Round up to require more shares when calculating the slippage |
| 111 | `previewRedeem` | Floor | Round down to give less assets when calculating the slippage |
| 232 | `_convertToShares` | Variable (passed as arg) | Depends on the arg |
| 240 | `_convertToAssets` | Variable (passed as arg) | Depends on the arg |
| 248 | `_creditAvailable` | Floor | Rounding down ensures that the calculated limit is slightly lower or equal to the exact mathematical value |
| 251 | `_creditAvailable` | Floor | Rounding down ensures that the calculated limit is slightly lower or equal to the exact mathematical value |
| 280 | `_debtExcess` | Floor | Rounding down ensures that the calculated limit is slightly lower or equal to the exact mathematical value |
| 305 | `_calculateLockedProfit` | Floor | Prevents accidentally distributing profit that hasn't fully vested yet |
| 324 | `_checkSlippage` | Floor | Consistency with `actualExchangeRate` |
| 325 | `_checkSlippage` | Floor | Don't overstate performance |
| 328 | `_checkSlippage` | Ceil | Round up the percentage loss |
| 343 | `_currentPnL` | Floor | Consistency with `feesCollected` in the `_report()` function |
| 467 | `_report` | Floor | Favor the users over the protocol |