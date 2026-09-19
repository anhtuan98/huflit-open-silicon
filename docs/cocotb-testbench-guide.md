# Writing a cocotb Testbench: A Line-by-Line Walkthrough

| | |
|---|---|
| **Program** | HUFLIT Open Silicon (codename Vega) |
| **Worked example** | [`designs/counter3/verify/test_counter3.py`](../designs/counter3/verify/test_counter3.py) |
| **Audience** | Anyone about to write their first cocotb testbench |
| **Status** | Concept/teaching reference — not a program milestone |
| **Vietnamese version** | [`docs/vi/cocotb-huong-dan-viet-testbench.md`](vi/cocotb-huong-dan-viet-testbench.md) |
| **Why this matters for the program** | This is exactly the skill Gate 0 needs (`docs/OPEN_SILICON_KICKOFF.md` §4, weeks 7-12): writing a cocotb testbench against someone else's RTL, on `obi_uart`/`apb_timer`, to find a real bug and get a PR merged. |

## 0. The core idea before reading any code

cocotb lets you write a testbench **in Python instead of Verilog**, then
drive the RTL running inside a simulator (Verilator, here) — push signals
in, read signals out, compare against expectations.

The strangest thing for a newcomer: a test does not run top-to-bottom like
an ordinary Python function. It runs on **simulated time**. To "wait for
the next clock edge," you `await` — you hand control back to the simulator
until that event actually happens. That is why every cocotb test is an
`async def` function.

## 1. `Makefile` — the bridge between Python and Verilator

```makefile
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(shell pwd)/../src/counter3.v
TOPLEVEL = counter3
MODULE = test_counter3
include $(shell cocotb-config --makefiles)/Makefile.sim
```

Four things to declare, cocotb handles the rest:
- `SIM` — which simulator (Verilator)
- `VERILOG_SOURCES` — which RTL file(s)
- `TOPLEVEL` — which module is the design root (`counter3`)
- `MODULE` — which Python file holds the tests (`test_counter3.py`, no
  `.py` suffix)

`make` will: compile `counter3.v` into a C++ model (via Verilator) → run
it → load `test_counter3.py` → call every function decorated with
`@cocotb.test()`.

## 2. Anatomy of `test_counter3.py`, line by line

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
```
Three essentials: `cocotb` (the test framework), `Clock` (a helper that
generates a clock waveform), `RisingEdge` (a helper meaning "wait for the
next rising edge").

### The first test — simplest, read this one first

```python
@cocotb.test()
async def test_reset_clears_count(dut):
    """count is 0 while rst is held."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.count.value) == 0
```

- `@cocotb.test()` — this decorator tells cocotb "this is a test case, run
  it." A file can have several such functions; each is an independent test.
- `dut` — the mandatory parameter, a **handle pointing at the design
  under simulation**. `dut.rst`, `dut.clk`, `dut.count` are exactly the
  three ports of `counter3.v` (`rst`, `clk`, `count`) — cocotb maps them
  automatically by name, no extra declaration needed.
- `cocotb.start_soon(Clock(...).start())` — **important**: this starts a
  coroutine that runs **in the background, indefinitely**, generating a
  10ns clock forever. `start_soon` means "run this, but don't wait for it
  to finish" (the clock never finishes) — different from `await`, which
  means "wait until this is done before continuing."
- `dut.rst.value = 1` — drive a value onto the `rst` port. This is how you
  "push a signal into" the design.
- `await RisingEdge(dut.clk)` — pause the test function here, hand control
  back to the simulator, and resume only once a rising edge of `clk`
  occurs. Calling it twice means "wait for two clock edges."
- `assert int(dut.count.value) == 0` — read the current value of `count`,
  cast to a Python int, compare. If wrong → `AssertionError` → cocotb
  marks this test **FAIL**.

**One-sentence summary:** start the clock in the background → hold
`rst=1` → wait two edges → check `count` is 0.

### The `reset()` helper — reusable logic

```python
async def reset(dut):
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
```

No `@cocotb.test()` — this is **not** a test case itself, just an ordinary
`async` helper function so multiple tests can share the same "standard
reset sequence": hold reset for 2 cycles, release it, then wait one more
cycle to be sure the design is running from a known state before real
checking begins.

### The second test — more involved, has a loop

```python
@cocotb.test()
async def test_counts_and_wraps(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset(dut)

    previous = int(dut.count.value)
    for _ in range(16):
        await RisingEdge(dut.clk)
        current = int(dut.count.value)
        expected = (previous + 1) % 8
        assert current == expected, f"expected {expected} after {previous}, got {current}"
        previous = current
```

- `await reset(dut)` — call the helper above, **with `await`** this time,
  because we need to actually wait for it to finish (unlike the Clock,
  which we deliberately did not wait for).
- A 16-iteration loop (twice the counter's 8-value period, so the 7→0
  wraparound is exercised at least twice, not seen once by luck).
- **The most important detail in this test:** `expected = (previous + 1)
  % 8` — the expectation is computed **from the value observed in the
  previous cycle**, not from "which cycle number this is since reset."
  This is a direct lesson from a real bug hit while writing this test
  (`docs/counter3-technical-report.md` §4.1): an earlier version
  hard-asserted "count must equal 1 on the very first cycle after reset" —
  and failed intermittently, because driving a signal's `.value` right
  after an `await RisingEdge` is not guaranteed to take effect on the very
  next edge (a simulator-scheduling detail, not an RTL bug). **Rule of
  thumb: assert relative to the value you just observed, avoid asserting
  against an assumed absolute point in time.**

## 3. Running it for real

```bash
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/counter3/verify \
  librelane-dev --skip make
```

The terminal prints a PASS/FAIL table for each `@cocotb.test()`, and
cocotb also writes `results.xml` (JUnit format) — the same file a CI
pipeline would consume to fail a build on a red test.

## 4. A small exercise worth doing before moving on

Add one more test to the end of `test_counter3.py`: check **reset applied
mid-count** (not just at the start) — count for a few cycles, then assert
`rst.value = 1` for one cycle, then check `count` goes back to 0
immediately after. This is exactly the kind of case that exposes an RTL
bug shaped like `if (rst && something)` instead of `if (rst)` — a common
real-world bug pattern to look for when verifying someone else's IP,
which is precisely the Gate 0 task ahead (`obi_uart`).

## References

- `designs/counter3/verify/test_counter3.py`, `Makefile` — the actual code
  this walkthrough is based on
- `docs/counter3-technical-report.md` §4 — the full verification section,
  including the off-by-one gotcha in more detail
- `docs/chip_making_a_to_z.md` — where "RTL verification" fits in the
  overall RTL-to-GDSII flow
- cocotb documentation: `docs.cocotb.org`
