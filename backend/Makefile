MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
CONTRACTS_MAKEFILE_DIR := $(MAKEFILE_DIR)/../contracts

include $(CONTRACTS_MAKEFILE_DIR)/.env

export

$(CONTRACTS_MAKEFILE_DIR)/.env:
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) $(CONTRACTS_MAKEFILE_DIR)/.env

.PHONY: test
test:
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) kill_local_blockchain
	@$(MAKE) -C $(CONTRACTS_MAKEFILE_DIR) run script=SetupPermit
	@bun test
