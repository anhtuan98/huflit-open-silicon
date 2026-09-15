---
marp: true
paginate: true
title: uart_top -- Second RTL-to-GDSII Design
---

# uart_top

**Second RTL-to-GDSII Design**

HUFLIT Open Silicon (Vega) — Phase 0, optional week 3-6 extension
Full report: `docs/uart-technical-report.md`

---

## Why a Second Design

- `counter3` alone already satisfied the week 3-6 gate.
- Two reasons to build a second one anyway:
  1. **Exercise more of the flow** -- a real FSM, more cells, an
     external async-looking input.
  2. **Rehearsal for Gate 0** -- `obi_uart` (pulp-platform/obi_peripherals)
     was chosen as the real upstream target; this design's byte-framing
     testbench is a direct warm-up for that one.

---

## The Design

```verilog
module uart_top #(parameter CLKS_PER_BIT = 4) (
    input  wire       clk, rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_serial, tx_busy,
    input  wire       rx_serial,
    output wire [7:0] rx_data,
    output wire       rx_done
);
```

8N1 framing (start=0, 8 data bits LSB-first, stop=1). `tx_serial` /
`rx_serial` are independent ports -- loopback is external.

---

## TX: 4-State FSM

`IDLE -> START -> DATA -> STOP -> IDLE`, each state held for
`CLKS_PER_BIT` cycles. No separate baud clock domain -- just a counter
derived from `clk`. `tx_busy` marks the whole frame duration.

## RX: Mid-Bit Sampling + Synchronizer

- Samples each bit near its **middle**, not its edge -- tolerates small
  clock misalignment with an external transmitter.
- `rx_serial` passes through a **2-flop synchronizer** before the FSM
  reads it -- standard metastability mitigation for an async input
  (the "CDC" concept from kickoff doc §5.3), even with one clock here.

---

## Verification: 3/3 Tests Pass

1. `test_tx_frames_byte` -- 0xA5 (not all-0/1, catches bit-order bugs),
   checks the full 10-bit frame.
2. `test_rx_decodes_byte` -- drives an external 8N1 frame, checks decode.
3. `test_tx_rx_loopback` -- software loopback wire, 5 edge-case bytes.

Same lesson as `counter3`: the TX helper waits on **`tx_busy`
transitions**, not an assumed fixed cycle count.

---

## Physical Config: The Surprise

```yaml
DESIGN_NAME: uart_top
VERILOG_FILES: dir::src/*.v
CLOCK_PERIOD: 10
CLOCK_PORT: clk
DESIGN_REPAIR_MAX_SLEW_PCT: 25
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15
```

**No `FP_SIZING: absolute`, no `DIE_AREA`, no PDN tuning** -- unlike
`counter3`. Default sizing lands at 75.3% utilization on its own.

---

## Finding #1: The Tiny-Design Fix Doesn't Generalize

- `counter3` (3 flip-flops, ~22 cells) needed manual floorplan/PDN
  tuning -- default sizing computed too small a die.
- `uart_top` (50 sequential, ~290 stdcells) needs **none of it**.
- **Rule:** try the minimal config first. Reach for `FP_SIZING:
  absolute` / PDN tuning only if `PDN-0185`/`DPL-0036` actually appear.
  Don't cargo-cult `counter3`'s `DIE_AREA` onto every new design.

---

## Finding #2: A New Signoff Gotcha

First attempt: **4 max-slew violations**, `ss` corner only, one
3-fanout net, ~7% over limit.

**Root cause:** resizer steps run *before* detailed routing -- optimize
against estimated parasitics, not final routed ones. A small gap can
survive to final signoff.

**Fix:** widen the resizer's own margin --
`DESIGN_REPAIR_MAX_SLEW_PCT: 25` / `GRT_..._PCT: 15` (defaults 20/10).
4 -> 0 violations, no other change.

---

## Debugging Trap Worth Knowing

On the failing run, `Checker.MaxSlewViolations` printed:
- a `WARNING` naming the violating corners, **then**
- a `VERBOSE` line: *"No max slew violations found"*

Same step, same run. Flow still exits 0 either way.

**Trust `design__max_slew_violation__count` in `metrics.json`, not
either log line.**

---

## Results -- Cells & Area

| Metric | Value |
|---|---|
| Standard cells | 290 (50 seq + 105 comb + buffers) |
| Fill / tap cells | 207 / 48 |
| Die area | 72.3 x 83.0 um (5,997 um^2) |
| Core utilization | **75.3%** (vs counter3's 5.24%) |

---

## Results -- Timing, Power, Signoff

| Metric | Value |
|---|---|
| Worst setup / hold slack (9 PVT corners) | +2.52 ns / +0.12 ns |
| Setup / hold / slew violations | 0 / 0 / 0 |
| Total power (nominal corner) | ~= 566.8 nW |
| DRC (Magic + KLayout) / LVS / antenna | 0 / 0 / 0 |

Tighter margins than `counter3` -- more real work per clock period,
taller clock tree (16 buffers vs 4). Still comfortably positive.

---

## Reproducing This Result

```bash
docker compose -f docker/docker-compose.yml build
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart/verify \
  librelane-dev --skip make
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/uart \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd config.yaml
```

---

## Where This Fits

- Week 3-6 gate already satisfied by `counter3` alone -- this is a bonus.
- Real next step: outreach to `pulp-platform/obi_peripherals`
  maintainers, then reuse this testbench's byte-framing patterns for
  `obi_uart`'s cocotb testbench (Gate 0, weeks 7-12).

---

## Questions?

`docs/uart-technical-report.md` — full write-up
`wiki/uart-signoff-sizing-and-slew-margin.md` — sizing & slew-margin deep dive
`docs/counter3-technical-report.md` — the first design this one builds on
