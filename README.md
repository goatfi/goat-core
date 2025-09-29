# Goat Core Contracts

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