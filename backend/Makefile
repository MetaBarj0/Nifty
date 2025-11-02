MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
CONTRACTS_MAKEFILE_DIR := $(MAKEFILE_DIR)/../contracts

include $(CONTRACTS_MAKEFILE_DIR)/.env

export

$(CONTRACTS_MAKEFILE_DIR)/.env:
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) $(CONTRACTS_MAKEFILE_DIR)/.env

.PHONY: setup_permit
setup_permit:
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) kill_local_blockchain
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) run script=SetupPermit

.PHONY: test
test: setup_permit
	@bun test

.PHONY: watch
watch: setup_permit
	@bun test --watch
