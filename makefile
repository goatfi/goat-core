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

coverage:
	@echo Creating test coverage for Goat Contracts
	@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

contract-% c-%:
	@echo Running tests for contract $*
	@forge test --match-contract $* -vvv

.PHONY: test coverage