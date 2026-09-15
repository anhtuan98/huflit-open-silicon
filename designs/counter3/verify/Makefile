SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = $(shell pwd)/../src/counter3.v
TOPLEVEL = counter3
MODULE = test_counter3

include $(shell cocotb-config --makefiles)/Makefile.sim
