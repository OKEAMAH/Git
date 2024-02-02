# SPDX-FileCopyrightText: 2024 Nomadic Labs <contact@nomadic-labs.com>
#
# SPDX-License-Identifier: MIT

KERNELS=risc-v-dummy risc-v-dummy.elf jstz
RISC_V_DIR=src/risc_v
RISC_V_DUMMY_DIR=src/risc_v/dummy_kernel
RISC_V_JSTZ_DIR=src/risc_v/jstz
RISC_V_TESTS_DIR=src/risc_v/tests

.PHONY: risc-v-sandbox
risc-v-sandbox:
	@make -C $(RISC_V_DIR) build-sandbox
	@ln -f $(RISC_V_DIR)/target/$(NATIVE_TARGET)/release/risc-v-sandbox $@

.PHONY: risc-v-dummy.elf
risc-v-dummy.elf:
	@make -C ${RISC_V_DUMMY_DIR} build
	@ln -f ${RISC_V_DUMMY_DIR}/target/riscv64gc-unknown-hermit/release/risc-v-dummy $@

.PHONY: risc-v-dummy
risc-v-dummy:
	@make -C ${RISC_V_DUMMY_DIR} build

.PHONY: jstz
jstz:
	@make -C ${RISC_V_JSTZ_DIR} build

.PHONY: risc-v-tests
risc-v-tests:
	@make -C ${RISC_V_TESTS_DIR} build

.PHONY: kernel_sdk
kernel_sdk:
	@make -f kernels.mk kernel_sdk

.PHONY: build
build: ${KERNELS} kernel_sdk risc-v-sandbox risc-v-tests

.PHONY: clang-supports-wasm
clang-supports-wasm:
	./scripts/kernels_check_clang.sh

.PHONY: build-deps
build-deps:
	@make -C ${RISC_V_DIR} build-deps

	# Iterate through all the toolchains. 'rustup show' will install the
	# toolchain in addition to showing toolchain information.
	@find src -iname 'rust-toolchain*' -execdir rustup show active-toolchain \; 2>/dev/null

.PHONY: test
test:
	@make -C ${RISC_V_DIR} test

.PHONY: check
check: build-deps
	@make -C ${RISC_V_DIR} check
	@make -C ${RISC_V_TESTS_DIR} check

.PHONY: clean
clean:
	@rm -f ${KERNELS}
	@make -C ${RISC_V_DIR} clean
	@rm -f risc-v-sandbox
	@make -C ${RISC_V_TESTS_DIR} clean
