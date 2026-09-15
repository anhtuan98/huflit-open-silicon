"""cocotb testbench for counter3: a 3-bit synchronous up-counter."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


async def reset(dut):
    """Hold rst for 2 cycles, release it, then wait one more cycle so the
    counter is guaranteed to be running from a known state afterwards."""
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_clears_count(dut):
    """count is 0 while rst is held."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.count.value) == 0


@cocotb.test()
async def test_counts_and_wraps(dut):
    """count increments by 1 each clock and wraps from 7 back to 0.

    Checked relative to the previous cycle's value rather than against an
    absolute cycle count tied to reset release timing -- deassertion of a
    signal set right after an await takes a simulator-dependent number of
    cycles to be observed by the DUT (see backlog.md for the cocotb/
    Verilator gotcha this sidesteps).
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    previous = int(dut.count.value)
    for _ in range(16):
        await RisingEdge(dut.clk)
        current = int(dut.count.value)
        expected = (previous + 1) % 8
        assert current == expected, f"expected {expected} after {previous}, got {current}"
        previous = current
