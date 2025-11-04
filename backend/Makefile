MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
CONTRACTS_MAKEFILE_DIR := $(MAKEFILE_DIR)/../contracts
FORGE_SCRIPT := SetupPermit

include $(CONTRACTS_MAKEFILE_DIR)/.env

export

$(CONTRACTS_MAKEFILE_DIR)/.env:
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) $(CONTRACTS_MAKEFILE_DIR)/.env

.PHONY: generate_contract_types
generate_contract_types:
	@bun install
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) clean build
	@bun x typechain --target ethers-v6 --out-dir typechain --glob $(CONTRACTS_MAKEFILE_DIR)/out/**.sol/*.json

.PHONY: setup_permit
setup_permit: generate_contract_types
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) kill_local_blockchain
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) run script=$(FORGE_SCRIPT)

.PHONY: test
test: setup_permit
	@bun test

.PHONY: watch
watch: setup_permit
	@bun test --watch
