MAKEFILE_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

include $(MAKEFILE_DIR)/.env

$(MAKEFILE_DIR)/.env:
	@cd $(MAKEFILE_DIR) && cp .env.sample .env \
		&& echo .env file created, ready to hold your precious and secret variable values.

.PHONY: build
build:
	@cd $(MAKEFILE_DIR) \
		&& git submodule update --init --recursive \
		&& forge build

.PHONY: test
test:
	@cd $(MAKEFILE_DIR) && forge test --gas-report

.PHONY: testv
testv:
	@cd $(MAKEFILE_DIR) && forge test -vvv

.PHONY: watch
watch:
	@cd $(MAKEFILE_DIR) && forge test -w

.PHONY: watchv
watchv:
	@cd $(MAKEFILE_DIR) && forge test -w -vvv

.PHONY: coverage
coverage:
	@cd $(MAKEFILE_DIR) && forge coverage

.PHONY: run_local_blockchain
run_local_blockchain: .anvil.pid
	@cd $(MAKEFILE_DIR) && [ -z "$$(pidof anvil)" ] && rm .anvil.pid && $(MAKE) .anvil.pid || return 0
	@cd $(MAKEFILE_DIR) && echo $$(pidof anvil) > .anvil.pid

.PHONY: kill_local_blockchain
kill_local_blockchain:
	@cd $(MAKEFILE_DIR) && [ -f .anvil.pid ] && kill "$$(cat .anvil.pid)" && rm .anvil.pid || echo "nothing to kill"

.PHONY: local_deploy
local_deploy: run_local_blockchain
	@cd $(MAKEFILE_DIR) \
		&& while true; do \
		forge script script/NiftyLocalDeploy.s.sol \
		  --private-key '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' \
		  --rpc-url local \
		  --broadcast \
		&& break || sleep 1; done

.PHONY: run
run: script=
run: build
	@cd $(MAKEFILE_DIR) && [ -z "$${script}" ] \
		&& echo 'You have to specify a script name' \
		&& exit 1 \
		|| exit 0
	@cd $(MAKEFILE_DIR) && [ ! -f "script/$${script}.s.sol" ] \
		&& echo "Unexisting script: script/$${script}.s.sol" \
		&& exit 1 \
		|| exit 0
	@cd $(MAKEFILE_DIR) && $(MAKE) local_deploy \
		&& forge script "script/$${script}.s.sol" \
		  --private-key '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80' \
		  --rpc-url local \
		  --broadcast

.anvil.pid:
	@cd $(MAKEFILE_DIR) \
		&& [ -z "$$(pidof anvil)" ] && \
		anvil \
		  --accounts 1 \
		  --mnemonic 'test test test test test test test test test test test junk' \
			--fork-url mainnet \
			--fork-block-number "${MAINNET_FORK_BLOCK}" \
			--host "${ANVIL_HOST}" --port "${ANVIL_PORT}" \
			--hardfork "${ANVIL_EVM_VERSION}" \
			& echo $$!>.anvil.pid || \
		echo $$(pidof anvil) > .anvil.pid

.PHONY: sepolia_deploy
sepolia_deploy:
	cd $(MAKEFILE_DIR) && forge script script/NiftySepoliaDeploy.s.sol --rpc-url sepolia --broadcast --verify

