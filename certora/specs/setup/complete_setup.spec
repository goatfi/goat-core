import "multistrategy_requirements.spec";
import "./summaries/multistrategy_summaries.spec";
import "./summaries/safe_approximations.spec";

use builtin rule viewReentrancy;

///////////////// FUNCTIONS /////////////////////

function SafeAssumptions(env e) {
    completeSetupForEnv(e);
    requireEnvFreeInvariants();
}

function requireEnvFreeInvariants() {
    requireInvariant debtRatioInvariant();
    requireInvariant totalDebtInvariant();
    requireInvariant totalAssetsInvariant();
}

function completeSetupForEnv(env e) {
    sceneContractsRequirements();
    nonPausedRequirements();
    nonReenteredRequirement();
    timestampRequirements(e);
    nonSceneAddressRequirements(e.msg.sender);
    assetToSharesRelationshipRequirements(e);
}

///////////////// DEFINITIONS /////////////////////

definition userAllowed(method f) returns bool = 
    f.isView ||
    f.selector == sig:deposit(uint256,address).selector ||
    f.selector == sig:mint(uint256,address).selector ||
    f.selector == sig:withdraw(uint256,address,address).selector ||
    f.selector == sig:redeem(uint256,address,address).selector ||
    f.selector == sig:transfer(address,uint256).selector ||
    f.selector == sig:transferFrom(address,address,uint256).selector ||
    f.selector == sig:approve(address,uint256).selector;

definition canChangeWithdrawOrder(method f) returns bool = 
    f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
    f.selector == sig:removeStrategy(address).selector ||
    f.selector == sig:setWithdrawOrder(address[]).selector;

definition canChangeDebtRatio(method f) returns bool =
    f.selector == sig:addStrategy(address,uint256,uint256,uint256).selector ||
    f.selector == sig:setStrategyDebtRatio(address,uint256).selector;

definition canChangeDebt(method f) returns bool =
    f.selector == sig:requestCredit().selector ||
    f.selector == sig:strategyReport(uint256,uint256,uint256).selector ||
    f.selector == sig:withdraw(uint256,address,address).selector ||
    f.selector == sig:redeem(uint256,address,address).selector;

definition canChangeGuardian(method f) returns bool =
    f.selector == sig:enableGuardian(address).selector ||
    f.selector == sig:revokeGuardian(address).selector;

///////////////// GHOSTS & HOOKS //////////////////

persistent ghost mapping(address => mathint) debtRatios {
    init_state axiom forall address s. debtRatios[s] == 0;
}

persistent ghost mapping(address => mathint) debts {
    init_state axiom forall address s. debts[s] == 0;
}

persistent ghost mapping(address => mathint) losses {
    init_state axiom forall address s. losses[s] == 0;
}

hook Sstore strategies[KEY address s].debtRatio uint256 new_debtRatio {
    debtRatios[s] = new_debtRatio;
}

hook Sstore strategies[KEY address s].totalDebt uint256 new_debt {
    debts[s] = new_debt;
}

hook Sstore strategies[KEY address s].totalLoss uint256 new_loss {
    losses[s] = new_loss;
}

hook Sload uint256 debtRatio strategies[KEY address s].debtRatio {
    require(debtRatios[s] == debtRatio, "Keep the ghost hooked");
}

hook Sload uint256 debt strategies[KEY address s].totalDebt {
    require(debts[s] == debt, "Keep the ghost hooked");
}

hook Sload uint256 loss strategies[KEY address s].totalLoss {
    require(losses[s] == loss, "Keep the ghost hooked");
}

hook Sload uint32 lastReport strategies[KEY address s].lastReport {
    if(lastReport == 0) require(debtRatios[s] == 0, "A non active strategy cannot have >0 debt ratio");
}

///////////////// INVARIANTS /////////////////////

invariant debtRatioInvariant()
    multistrategy.debtRatio() == (usum address s. debtRatios[s]) && multistrategy.debtRatio() <= 10000
    filtered {f-> canChangeDebtRatio(f)}

invariant totalDebtInvariant()
    multistrategy.totalDebt() == (usum address s. debts[s])
    filtered {f-> canChangeDebt(f)}

invariant totalAssetsInvariant() 
    adapter.totalAssets() == adapter.totalDebt() + adapter.currentGain() - adapter.currentLoss();