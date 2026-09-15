# uart_top — Second RTL-to-GDSII Design: Technical Report

| | |
|---|---|
| **Program** | HUFLIT Open Silicon (codename Vega) |
| **Design under study** | [`designs/uart/`](../designs/uart/) |
| **Milestone** | Phase 0, weeks 3-6 (`docs/OPEN_SILICON_KICKOFF.md` §4) — optional second learning design |
| **Run date** | 2026-09-15 |
| **Status** | Complete: full DRC/LVS/timing sign-off. Not submitted for tape-out (ADR-OS-003) |
| **Audience** | Teaching material — companion to [`docs/counter3-technical-report.md`](counter3-technical-report.md), the program's first worked example |

## Abstract

This report documents `uart_top`, the second design taken through a
complete RTL-to-GDSII flow in the HUFLIT Open Silicon program: an 8N1
UART transmitter and receiver pair. Where `counter3` (the program's
first design) was deliberately trivial, `uart_top` was chosen precisely
because it is *not* — it has a real finite-state machine on both the
transmit and receive side, a bit-timing counter, and an external,
unclocked input that must be synchronized before use. The result is a
useful contrast with `counter3` on the physical-implementation side: this
design's default floorplan sizing worked with no manual tuning at all,
the opposite of `counter3`'s experience, which is itself the report's
central teaching point about when tiny-design workarounds are and are not
needed. A new signoff issue — a post-route max-slew violation visible at
only one PVT corner — is also documented in full, including a debugging
trap in the flow's own log output.

## 1. Purpose and Context

Per `docs/OPEN_SILICON_KICKOFF.md` §4, weeks 3-6 of Phase 0 only require
*one* self-written design taken through full sign-off — `counter3`
already satisfied that gate on its own (see
`docs/counter3-technical-report.md`). `uart_top` was built afterward as
an explicitly optional second design, for two reasons stated when the
decision was made:

1. **Exercise more of the flow.** `counter3` is three flip-flops and an
   adder; its physical implementation needed hand-tuning specifically
   *because* it is that small (§5.1 of the counter3 report). A design
   with a real FSM, more registers, and an external asynchronous-looking
   input tests whether that tuning generalizes or was a one-off artifact
   of extreme smallness.
2. **Rehearse for the actual Gate 0 target.** The program's next
   milestone (weeks 7-12) is contributing a cocotb testbench to a real
   upstream open-source IP — specifically `obi_uart`
   (`pulp-platform/obi_peripherals`, chosen after a shortlist review; see
   `backlog.md`). Writing this design's own UART testbench first —
   framing bytes, checking start/data/stop bits, driving an external
   serial input — is a direct rehearsal of the byte-framing checks that
   testbench will also need, before adding `obi_uart`'s own bus protocol
   on top.

## 2. RTL Design

The design is split into two independent modules plus a top-level wrapper
that instantiates both and does nothing else:
[`designs/uart/src/uart_tx.v`](../designs/uart/src/uart_tx.v),
[`designs/uart/src/uart_rx.v`](../designs/uart/src/uart_rx.v),
[`designs/uart/src/uart_top.v`](../designs/uart/src/uart_top.v).

```verilog
module uart_top #(
    parameter CLKS_PER_BIT = 4
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_serial,
    output wire       tx_busy,
    input  wire       rx_serial,
    output wire [7:0] rx_data,
    output wire       rx_done
);
```

`tx_serial` and `rx_serial` are separate top-level ports — nothing inside
this design ties transmit to receive. Loopback (needed to test both
halves against each other) is a testbench or board-level concern, not
something baked into the RTL. This is a deliberate interface choice: it
mirrors how a real UART peripheral in a larger SoC would expose two
independent pins to the outside world.

### 2.1 Transmitter: a 4-state FSM over a bit-timing counter

`uart_tx` frames a byte as 1 start bit (0) + 8 data bits (LSB-first) + 1
stop bit (1), using a 4-state FSM (`IDLE → START → DATA → STOP → IDLE`).
Each state holds for `CLKS_PER_BIT` clock cycles before advancing —
there is no separate baud-rate clock domain, only a slower *enable*
derived by counting `clk` edges. `tx_busy` is asserted for the full
duration of a frame, giving the caller (or, in this exercise, the
testbench) an unambiguous signal for when the next byte can be started.

### 2.2 Receiver: mid-bit sampling behind a synchronizer

`uart_rx` mirrors the transmitter's framing with a 5-state FSM (adding a
`CLEANUP` state after `STOP_BIT` to pulse `rx_done` for exactly one
cycle). Two design choices are worth naming explicitly:

- **Mid-bit sampling.** The receiver waits `(CLKS_PER_BIT - 1) / 2`
  cycles into the start bit before re-checking it, and samples each data
  bit at the same offset into its bit period. This is the standard UART
  receive technique: sampling near the middle of a bit, rather than at
  its edge, tolerates a small timing misalignment between an external
  transmitter's clock and the receiver's own clock — the two are not
  assumed to be phase-aligned.
- **Two-flop synchronizer on `rx_serial`.** `rx_serial` is, by
  definition, driven by something outside this design's clock domain (an
  external transmitter, or in this design's own loopback test, this
  same module's own `tx_serial` — see §3). Before the receive FSM ever
  looks at it, `rx_serial` passes through two back-to-back flip-flops
  (`rx_sync`, then `rx_serial_sync`). This is the standard mitigation for
  metastability on an asynchronous input crossing into a clocked design —
  the same concept the kickoff doc's FPGA teaching track (§5.3) names as
  "CDC" (clock domain crossing), here applied defensively even without a
  second physical clock domain in this exercise.

## 3. Verification

[`designs/uart/verify/test_uart.py`](../designs/uart/verify/test_uart.py)
uses the same cocotb classic Makefile flow as `counter3`, against
Verilator. Three tests:

1. **`test_tx_frames_byte`** — starts a transmit of `0xA5` (chosen
   because it is neither all-0 nor all-1, so it catches bit-order bugs
   that an all-same-value byte would hide) and samples `tx_serial` once
   per bit period, checking the full 10-bit frame: start bit, 8 data
   bits in the expected order, stop bit.
2. **`test_rx_decodes_byte`** — drives an idealized external 8N1 frame
   (`0x5A`) directly onto `rx_serial` and checks `rx_data` against it
   once `rx_done` pulses.
3. **`test_tx_rx_loopback`** — continuously copies `tx_serial` onto
   `rx_serial` (a software loopback wire) and sends 5 bytes chosen to
   cover edge patterns (`0x00`, `0xFF`, `0xA5`, `0x3C`, `0x81`), checking
   each is received unchanged.

All three pass (3/3). One methodology point carried over directly from
`counter3`'s cocotb gotcha (see that report's §4.1): the helper that
starts a transmit does **not** assume a fixed cycle count for how long a
frame takes. It waits on the actual `tx_busy` signal transitions instead:

```python
async def start_tx(dut, byte):
    dut.tx_data.value = byte
    dut.tx_start.value = 1
    await RisingEdge(dut.clk)
    dut.tx_start.value = 0
    while int(dut.tx_busy.value) == 0:
        await RisingEdge(dut.clk)
    while int(dut.tx_busy.value) == 1:
        await RisingEdge(dut.clk)
```

This is the same lesson generalized: prefer waiting on an observable
signal transition over assuming a fixed timing relationship, even when
the fixed count is computable in principle.

## 4. Physical Implementation (LibreLane)

[`designs/uart/config.yaml`](../designs/uart/config.yaml), in full:

```yaml
# Basics
DESIGN_NAME: uart_top
VERILOG_FILES: dir::src/*.v
CLOCK_PERIOD: 10
CLOCK_PORT: clk

# Timing repair
DESIGN_REPAIR_MAX_SLEW_PCT: 25
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15

# Technology-Specific Configs
pdk::sky130*:
  CLOCK_PERIOD: 10.0
```

Two things stand out by comparison with `counter3`'s config, and both
are the point of building this second design at all.

### 4.1 No floorplan/PDN tuning needed — and that is the finding

`counter3`'s config needed `FP_SIZING: absolute`, an explicit oversized
`DIE_AREA`, and a widened PDN strap pattern, because its default,
percentage-based floorplan sizing computed a die too small once PDN
straps and hold-fix buffers needed room (see that report's §5.1). None of
that is present here. `uart_top` — at 50 sequential cells and roughly 290
standard cells total versus `counter3`'s 3 and ~22 — signs off cleanly
with LibreLane's **default** sizing, landing at 75.3% core utilization on
its own with no manual intervention.

This is not a contradiction of the earlier finding; it confirms its
scope. The tiny-design floorplan problem is specific to designs small
enough that PDN and buffer routing overhead dominates the die — a
handful of flip-flops, not fifty. The practical rule this pair of designs
establishes: **try the default, minimal config first; reach for the
`FP_SIZING: absolute` / PDN-tuning block only if `PDN-0185` or `DPL-0036`
actually appear, or if `design__instance__utilization` in a first attempt
comes out implausibly high.** Copying `counter3`'s `DIE_AREA` onto every
new design regardless of size would be cargo-culting a fix for a problem
that may not exist. Full write-up:
[`wiki/uart-signoff-sizing-and-slew-margin.md`](../wiki/uart-signoff-sizing-and-slew-margin.md).

### 4.2 A new signoff problem: post-route max-slew, one corner only

The first attempt at this design's flow completed with **4 max-slew
violations** — all at the `ss` (slow) process corner only, all on the
same 3-fanout net, each only about 7% over the 0.75 ns limit. The root
cause: LibreLane's design-repair (resizer) steps run *before* detailed
routing, so they optimize against estimated parasitics from placement
and global routing, not the final detailed-route-extracted ones. A small
residual gap between the two can survive all the way to the final
post-route static timing analysis, with no later step left to fix it.

**Fix:** widen the resizer's own slew-repair margin, so it targets a
stricter-than-necessary slew during design repair and leaves headroom to
absorb the later degradation:

```yaml
DESIGN_REPAIR_MAX_SLEW_PCT: 25       # default 20
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15   # default 10
```

This took the violation count from 4 to 0 on the rerun, no other change
needed.

**A debugging trap along the way, worth flagging on its own:** on the
failing run, the flow's own `Checker.MaxSlewViolations` step printed a
`WARNING` block naming the violating corners, immediately followed by a
`VERBOSE` line reading *"No max slew violations found"* — from the same
step, in the same run, with the flow still exiting 0 ("Flow complete")
either way. **Neither log line can be trusted as the verdict on its
own.** The only reliable source is `design__max_slew_violation__count` in
`final/metrics.json`, or the per-corner `checks.rpt` under the
`*-openroad-stapostpnr` run directory, which names the actual violating
pin and margin. This run's final, clean log (after the fix) reads
unambiguously: `No max slew violations found` — with the metric to match.

## 5. Results

Metrics below are pulled directly from
`designs/uart/runs/RUN_2026-09-15_07-44-22/final/metrics.json` (not
committed — regenerate by re-running the flow per §6).

### 5.1 Cell counts and area

| Metric | Value |
|---|---|
| Flow stages completed | 76 / 76, 0 errors |
| Standard cells (`design__instance__count__stdcell`) | 290 |
| Sequential cells | 50 |
| Combinational cells | 105 |
| Clock buffers | 16 |
| Hold-fix buffers | 36 |
| Timing-repair buffers (incl. the slew fix from §4.2) | 69 |
| Inverters | 2 |
| Fill cells | 207 |
| Tap/endcap cells | 48 |
| Total placed instances | 497 (= 290 stdcell + 207 fill, same accounting pattern as `counter3` — see [`wiki/librelane-metrics-json.md`](../wiki/librelane-metrics-json.md)) |
| Die area | 72.265 µm × 82.985 µm (5,996.91 µm²) |
| Core area | 3,661.01 µm² |
| Core utilization | 75.3% |

At 75.3% utilization versus `counter3`'s 5.24%, this design's die is
doing real work — the direct physical consequence of §4.1's finding.

### 5.2 Timing and power

| Metric | Value |
|---|---|
| Target clock period | 10 ns (100 MHz) |
| Worst-case setup slack (across all PVT corners) | +2.52 ns (met) |
| Worst-case hold slack (across all PVT corners) | +0.12 ns (met) |
| Setup / hold violations | 0 / 0 |
| Max slew / max capacitance / max fanout violations | 0 / 0 / 0 (see §4.2 for how this got to zero) |
| Total power (nominal corner, 25 °C, 1.8 V) | ≈ 566.8 nW |
| — internal power | ≈ 457.0 nW |
| — switching power | ≈ 109.7 nW |
| — leakage power | ≈ 3.5 pW (negligible) |

Both worst-case margins are noticeably tighter than `counter3`'s (+4.96
ns setup, +0.41 ns hold) — expected, since this design does
proportionally more real work per clock period and has a taller,
higher-fanout clock tree (16 clock buffers versus 4). Both remain
comfortably positive at the same conservative 100 MHz target.

### 5.3 Routing and signoff

| Check | Result |
|---|---|
| Global route wirelength / vias | 6,679 / 1,500 |
| Detailed route wirelength / vias | 3,777 / 1,540 |
| Magic DRC errors | 0 |
| KLayout DRC errors | 0 |
| Magic illegal-overlap errors | 0 |
| GDS-vs-layout XOR differences | 0 |
| LVS (schematic vs. layout) errors | 0 |
| Antenna violations | 0 |

Every checker in the flow log reports clean, in this order: Lint clear →
Yosys check clear → power-grid clear → routing DRC clear → disconnected
pins clear → XOR clear → Magic DRC clear → KLayout DRC clear →
illegal-overlap clear → LVS clear → no setup violations → no hold
violations → no max-slew violations → no max-cap violations. The final
GDSII
(`designs/uart/runs/RUN_2026-09-15_07-44-22/final/gds/uart_top.gds`,
~607 KB) is kept as local evidence only — gitignored, and not a
submission artifact (ADR-OS-003).

## 6. Reproducing This Result

```bash
# 1. Build the toolchain image (once, shared with counter3)
docker compose -f docker/docker-compose.yml build

# 2. Run the cocotb testbench
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart/verify \
  librelane-dev --skip make

# 3. Run the full LibreLane flow (PDK must be explicit -- see the
#    counter3 report §2 for why)
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd config.yaml

# 4. Inspect the result
ls designs/uart/runs/RUN_*/final/gds/
cat designs/uart/runs/RUN_*/final/metrics.json
```

## 7. Relationship to the Program Roadmap

This design is an optional addition on top of an already-satisfied
week 3-6 gate (`counter3` alone was sufficient). Its purpose going
forward is §1's second reason: rehearsal for the real Gate 0 work. The
next concrete step (tracked in `backlog.md`) is outreach to the
`pulp-platform/obi_peripherals` maintainers — confirming they would
accept a cocotb-based testbench and that its register interface (PR #9,
in flight at the time of writing) is stable enough to target — before
investing in writing that testbench, reusing this design's byte-framing
test patterns as the starting point.

## References

- `docs/counter3-technical-report.md` — the program's first design, and
  the report this one deliberately mirrors in structure
- `docs/OPEN_SILICON_KICKOFF.md` — program roadmap and stage gates
- `wiki/uart-signoff-sizing-and-slew-margin.md` — full write-up of §4
- `wiki/librelane-config-for-tiny-designs.md` — the counter3-side of the
  floorplan/PDN sizing comparison in §4.1
- `wiki/librelane-metrics-json.md` — how to read `metrics.json` correctly
- `backlog.md` — running log, including the `obi_uart` Gate 0 decision

## Changelog

| Version | Date | Change |
|---|---|---|
| v1.0 | 2026-09-15 | First version, written up after the 2026-09-15 run. |
