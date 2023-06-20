KERNELS = evm_kernel.wasm
SDK_DIR=src/kernel_sdk
EVM_DIR=src/kernel_evm
SEQUENCER_DIR=src/kernel_sequencer

define build_check
	ifeq ($($(1)), 0)
		@make -C $(2) build
	else
		@make -C $(2) build check
	endif
endef

define build_sdk
	$(call build_check,$(1),$(SDK_DIR))
	@cp $(SDK_DIR)/target/$(NATIVE_TARGET)/release/smart-rollup-installer .
endef

define build_evm
	$(call build_check,$(1),$(EVM_DIR))
	@cp $(EVM_DIR)/target/wasm32-unknown-unknown/release/evm_kernel.wasm $@
	@wasm-strip $@
endef

define build_sequencer
	$(call build_check,$(1),$(SEQUENCER_DIR))
	@cp $(SEQUENCER_DIR)/target/wasm32-unknown-unknown/release/examples/sequenced_kernel.wasm $@
	@wasm-strip $@
endef

.PHONY: all
all: build-dev-deps check test build

.PHONY: kernel_sdk
kernel_sdk:
	$(call build_sdk,0)

evm_kernel.wasm:
	$(call build_evm,0)

sequenced_kernel.wasm:
	$(call build_sequencer,0)

build-check-sdk:
	$(call build_sdk,1)

build-check-evm:
	$(call build_evm,1)

build-check-sequencer:
	$(call build_sequencer,1)

.PHONY: build
build: ${KERNELS} kernel_sdk sequenced_kernel.wasm

.PHONY: build-dev-deps
build-dev-deps: build-deps
	@make -C ${SDK_DIR} build-dev-deps
	@make -C ${EVM_DIR} build-dev-deps
	@make -C ${SEQUENCER_DIR} build-dev-deps

.PHONY: build-deps
build-deps:
	@make -C ${SDK_DIR} build-deps
	@make -C ${EVM_DIR} build-deps
	@make -C ${SEQUENCER_DIR} build-deps

.PHONY: test
test:
	@make -C ${SDK_DIR} test
	@make -C ${EVM_DIR} test
	@make -C ${SEQUENCER_DIR} test

.PHONY: check
check:
	@make -C ${SDK_DIR} check
	@make -C ${EVM_DIR} check
	@make -C ${SEQUENCER_DIR} check

.PHONY: publish-sdk-deps
publish-sdk-deps: build-deps
	@make -C ${SDK_DIR} publish-deps

.PHONY: publish-sdk
publish-sdk:
	@make -C ${SDK_DIR} publish

.PHONY: clean
clean:
	@rm -f ${KERNELS}
	@make -C ${SDK_DIR} clean
	@make -C ${EVM_DIR} clean
	@make -C ${SEQUENCER_DIR} clean
