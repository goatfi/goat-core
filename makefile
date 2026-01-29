install:
	@foundryup
	@forge soldeer install

build:
	@forge build --sizes --force

test:
	@echo Running all Goat tests
	@forge test -vvv

gas-report:
	@echo Creating gas report for Goat Contracts
	@forge test --gas-report

gas-benchmark:
	@echo Creating Gas Snapshot Reference
	@forge test --match-path test/gas/GasBenchmarks.t.sol --gas-snapshot-check=true

coverage:
	@echo Creating test coverage for Goat Contracts
	@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage && open coverage/index.html

contract-% c-%:
	@echo Running tests for contract $*
	@forge test --match-contract $* -vvv

.PHONY: test coverage