---
sources: [designs/uart/config.yaml, designs/uart/runs/*/final/metrics.json]
related: [[librelane-config-for-tiny-designs], [librelane-metrics-json]]
created: 2026-09-15
updated: 2026-09-15
---

# uart: Sizing Threshold and Post-Route Slew Margin

## Entry Points
- `designs/uart/config.yaml` -- a ~50-sequential-cell design (8N1 UART TX +
  RX) that signs off clean with LibreLane's **default** percentage-based
  floorplan sizing (`FP_CORE_UTIL`) -- no `FP_SIZING: absolute` / `DIE_AREA`
  / PDN tuning block needed, unlike `designs/counter3/config.yaml`.

## Key Patterns
- The "tiny design breaks default floorplan sizing" problem documented in
  [[librelane-config-for-tiny-designs]] is specific to genuinely tiny
  designs (`counter3`: 3 flip-flops, ~10-20 cells). `uart_top` (50
  sequential cells, ~290 stdcells total) hit no `PDN-0185` / `DPL-0036`
  at all with a fully default config -- default sizing landed at 75%
  utilization on its own. **Don't assume every new design needs the
  counter3 floorplan/PDN block; try the minimal config first and check
  `design__instance__utilization` / whether PDN generation fails before
  reaching for it.**
- A different, unrelated problem showed up instead: `design__max_slew_violation__count`
  was 4 (all four at the `*_ss_100C_1v60` process corners only, all on one
  3-fanout net, only ~7% over the 0.75 ns limit). Root cause: the design
  repair (resizer) steps run *before* detailed routing, so they optimize
  against estimated (placement/global-route) parasitics, not the final
  detailed-route-extracted ones -- a small residual violation from that
  parasitic gap can survive all the way to the final post-route STA
  checker with nothing left to fix it. Confirmed by reading the actual
  violating pin in `runs/*/55-openroad-stapostpnr/nom_ss_100C_1v60/checks.rpt`
  rather than trusting the top-level "No max slew violations found" line
  (see Gotchas below).
- **Fix:** widen the resizer's slew-repair margin so it targets a
  stricter-than-necessary slew during design repair, leaving headroom to
  absorb the later degradation:
  ```yaml
  DESIGN_REPAIR_MAX_SLEW_PCT: 25       # default 20
  GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15   # default 10
  ```
  This took `design__max_slew_violation__count` from 4 to 0 on the rerun
  with no other config change. Defaults for these live in
  `librelane/steps/openroad.py`'s `RepairDesignPostGPL` /
  `RepairDesignPostGRT` step classes.

## Search Shortcuts
- Grep: `DESIGN_REPAIR_MAX_SLEW_PCT`, `GRT_DESIGN_REPAIR_MAX_SLEW_PCT`,
  `design__max_slew_violation__count`
- Dir: `designs/uart/config.yaml`, `designs/*/runs/*/*/checks.rpt`

## Gotchas
- **The `Checker.MaxSlewViolations` step's own log is self-contradictory
  when a violation exists:** it prints a `WARNING` block listing the
  violating corners ("Max Slew violations found in the following
  corners: ..."), immediately followed by a `VERBOSE` line reading "No
  max slew violations found" -- from the same step, in the same run. The
  flow still exits 0 ("Flow complete") either way. **Do not trust either
  log line as the verdict** -- check `design__max_slew_violation__count`
  in `final/metrics.json` directly, or read the per-corner
  `checks.rpt` under the `*-openroad-stapostpnr` run directory for the
  actual violating pin and margin.
