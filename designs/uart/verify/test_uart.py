"""cocotb testbench for uart_top: an 8N1 UART transmitter + receiver.

CLKS_PER_BIT must match uart_tx.v / uart_rx.v's default parameter value --
there is no cocotb-side introspection of the Verilog parameter in this
classic Makefile flow, so the two are kept in sync by hand.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLKS_PER_BIT = 4


async def reset(dut):
    """Hold rst for 2 cycles, release it, then wait one more cycle."""
    dut.rst.value = 1
    dut.tx_start.value = 0
    dut.tx_data.value = 0
    dut.rx_serial.value = 1  # idle line is high
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


async def start_tx(dut, byte):
    """Pulse tx_start for one cycle and wait until the frame is fully sent.

    Waits for the actual tx_busy transitions rather than assuming a fixed
    number of cycles -- see designs/counter3's cocotb gotcha (backlog.md)
    for why an absolute cycle count tied to an assumed timing is fragile.
    """
    dut.tx_data.value = byte
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    while int(dut.tx_busy.value) == 0:
        await RisingEdge(dut.clk)
    while int(dut.tx_busy.value) == 1:
        await RisingEdge(dut.clk)


async def drive_rx_frame(dut, byte):
    """Drive one 8N1 frame onto rx_serial: start(0), 8 data bits LSB-first,
    stop(1), each held for CLKS_PER_BIT cycles -- an idealized transmitter
    at the same bit rate the receiver expects."""
    bits = [0] + [(byte >> i) & 1 for i in range(8)] + [1]
    for bit in bits:
        dut.rx_serial.value = bit
        for _ in range(CLKS_PER_BIT):
            await RisingEdge(dut.clk)


async def loopback_wire(dut):
    """Continuously copy tx_serial onto rx_serial, modelling a wire tying
    TX out to RX in on this same DUT."""
    while True:
        await RisingEdge(dut.clk)
        dut.rx_serial.value = dut.tx_serial.value


@cocotb.test()
async def test_tx_frames_byte(dut):
    """TX frames a byte as start(0) + 8 data bits LSB-first + stop(1)."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    byte = 0b10100101  # 0xA5 -- deliberately not all-0/all-1, catches bit-order bugs
    dut.tx_data.value = byte
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0

    # start bit + 8 data bits + stop bit = 10 bit periods, CLKS_PER_BIT
    # cycles each; sample tx_serial on the last cycle of each bit period.
    bits_observed = []
    for _ in range(10):
        for _ in range(CLKS_PER_BIT):
            await RisingEdge(dut.clk)
        bits_observed.append(int(dut.tx_serial.value))

    assert bits_observed[0] == 0, "start bit must be 0"
    expected_data_bits = [(byte >> i) & 1 for i in range(8)]
    assert bits_observed[1:9] == expected_data_bits, (
        f"data bits mismatch: got {bits_observed[1:9]}, expected {expected_data_bits}"
    )
    assert bits_observed[9] == 1, "stop bit must be 1"

    while int(dut.tx_busy.value) == 1:
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_rx_decodes_byte(dut):
    """RX correctly decodes an externally driven 8N1 frame."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    byte = 0x5A
    cocotb.start_soon(drive_rx_frame(dut, byte))
    await RisingEdge(dut.rx_done)
    assert int(dut.rx_data.value) == byte, (
        f"expected {byte:#04x}, got {int(dut.rx_data.value):#04x}"
    )


@cocotb.test()
async def test_tx_rx_loopback(dut):
    """Bytes sent by TX, looped back onto RX, are received unchanged."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)
    cocotb.start_soon(loopback_wire(dut))

    for byte in (0x00, 0xFF, 0xA5, 0x3C, 0x81):
        dut.tx_data.value = byte
        dut.tx_start.value = 1
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0

        await RisingEdge(dut.rx_done)
        received = int(dut.rx_data.value)
        assert received == byte, f"loopback mismatch: sent {byte:#04x}, got {received:#04x}"

        while int(dut.tx_busy.value) == 1:
            await RisingEdge(dut.clk)
