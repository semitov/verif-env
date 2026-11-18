# Hello-world test: proves Verilator, cocotb, pyuvm and cocotb-coverage work together.
#
#   make           run the simulation test
#   make WAVES=1   also write a waveform (dump.fst in this folder): open it with VaporView
#   make formal    run the formal check (SymbiYosys + Boolector)
#   make clean     remove build output

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(CURDIR)/counter.sv
COCOTB_TOPLEVEL = counter
COCOTB_TEST_MODULES = test_counter

# Waveforms in FST format (smaller than VCD); cocotb's Verilator wrapper writes dump.fst
ifeq ($(WAVES),1)
  EXTRA_ARGS += --trace-fst --trace-structs
  SIM_ARGS += --trace
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

# Formal hello-world (SymbiYosys). Kept after the include so `make` alone still runs the simulation.
.PHONY: formal
formal:
	sby -f counter.sby
