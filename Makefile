# =========================
# Poseidon Build System
# =========================

# Tools
VERILATOR ?= verilator
YOSYS ?= yosys

# Auto-find all SystemVerilog files
SV_FILES := $(shell find . -type f -name "*.sv")

# Versioning
VERSION ?= v1.1
DEV_DIR := builds/dev/$(VERSION)
FINAL_DIR := builds/final

# Default target
.PHONY: all
all: sim

# =========================
# Simulation
# =========================
.PHONY: sim
sim:
	@echo "=== Running Simulation ==="
	$(VERILATOR) --cc --exe --build --trace --timing -top if_stage_tb $(SV_FILES)

# =========================
# Lint (Verilator lint mode)
# =========================
.PHONY: lint
lint:
	@echo "=== Linting RTL ==="
	$(VERILATOR) --lint-only -Wall $(SV_FILES)

# =========================
# Dev Synthesis Build
# =========================
.PHONY: dev
dev:
	@echo "=== Dev Synthesis ($(VERSION)) ==="
	mkdir -p $(DEV_DIR)
	echo $(SV_FILES) | tr ' ' '\n' > filelist.f
	$(YOSYS) -p "read -sv -f filelist.f; hierarchy -check -top poseidon_top; synth; write_json $(DEV_DIR)/design.json"
	rm -f filelist.f

# =========================
# Final Production Build
# =========================
.PHONY: build
build:
	@echo "=== Final Production Build ==="
	mkdir -p $(FINAL_DIR)
	echo $(SV_FILES) | tr ' ' '\n' > filelist.f
	$(YOSYS) -p "read -sv -f filelist.f; hierarchy -check -top poseidon_top; synth -flatten -noabc; opt -full; write_json $(FINAL_DIR)/final.json"
	rm -f filelist.f

# =========================
# Clean
# =========================
.PHONY: clean
clean:
	@echo "=== Cleaning ==="
	rm -rf obj_dir builds filelist.f *.vcd
