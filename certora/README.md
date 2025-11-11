# Running the Certora CLI

The Certora Prover is a Formal Verification tool that is run via the Certora CLI.

Link to the docs: https://docs.certora.com/en/latest/index.html

### Requirements

- Have the Certora CLI intsalled.
- If running it on the cloud, have a Certora Key added to .zshrc

### Execution

Use the configuration files `.conf` to verify the specifications.

`$ certoraRun certora/conf/adapter/OwnerSafety.conf`

# High Level Properties (HLP)

### Preview Correctness

These high level properites prove that the return values of the preview functions are consistent with the
execution of the Deposit/Mint/Withdraw/Redeem functions.

- HLP_PreviewDepositCorrectness()
- HLP_HLP_PreviewMintCorrectness()
- HLP_PreviewWithdrawCorrectness()
- HLP_PreviewRedeemCorrectness()
