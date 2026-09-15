SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = $(shell pwd)/../src/uart_tx.v $(shell pwd)/../src/uart_rx.v $(shell pwd)/../src/uart_top.v
TOPLEVEL = uart_top
MODULE = test_uart

include $(shell cocotb-config --makefiles)/Makefile.sim
