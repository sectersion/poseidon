# Root Makefile — simulate & synth

# Find all SystemVerilog files
SV_FILES := $(shell find . -type f -name "*.sv")
BUILD_DIR ?= builds

# Default: simulate
.PHONY: all sim synth clean
all: sim

# Run Verilator simulation
sim:
	@echo "=== Running Verilator sim with all .sv ==="
	verilator --cc --exe --build --trace $(SV_FILES)

# Synthesis placeholder (e.g. with Yosys)
# You’ll want to replace yosys script with your actual synth script
synth:
	@echo "=== Synthesizing design ==="
	mkdir -p $(BUILD_DIR)/$(DEV_VERSION)
	yosys -p "read_verilog $(SV_FILES) ; synth_ice40 -top top_module ; write_json $(BUILD_DIR)/$(DEV_VERSION)/design.json"

clean:
	rm -rf obj_dir $(BUILD_DIR)
