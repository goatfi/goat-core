![Core](https://apricot-many-flamingo-613.mypinata.cloud/ipfs/bafkreien2vagdlnouzxop3r72f5ridnuy67scxtdkgwpxh6hsmqitoknc4)
# Goat Core Contracts

This repository contains the the codebase for the core infrastructure of Goat Multistrategy contracts, built with Foundry. <br>
It also contains the spec and configuration files used to formaly verify the codebase with Certora.

[![codecov](https://codecov.io/gh/goatfi/goat-core/graph/badge.svg?token=LNVEJLRAH1)](https://codecov.io/gh/goatfi/goat-core)

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
