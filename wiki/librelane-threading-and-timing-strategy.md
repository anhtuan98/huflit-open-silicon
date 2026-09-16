---
sources: [designs/picorv32/config.yaml, designs/picorv32/runs/*/32-openroad-repairdesignpostgpl/]
related: [[librelane-config-for-tiny-designs], [uart-signoff-sizing-and-slew-margin], [librelane-metrics-json]]
created: 2026-09-16
updated: 2026-09-16
---

# LibreLane Threading and Timing-Strategy Gotchas (picorv32-scale designs)

## Entry Points
- `designs/picorv32/config.yaml` -- a ~19k-instance design (real RV32I
  core, YosysHQ picorv32). First design in this repo big enough to
  surface threading and memory-scale issues invisible on `counter3`
  (~22 cells) and `uart` (~290 cells).

## Key Patterns

### 1. `OPENROAD_THREADS`/`STA_THREADS` auto-detect does not work in this container
Both default to `None`, documented as "equal to the machine's core
count" if unset. In practice, inside the IIC-OSIC-TOOLS container used by
this repo, unset means **1 thread**, confirmed two ways:
- Flow log: `[ORD-0032] Invalid thread number specification: None`,
  `OpenROAD will use None threads`.
- `docker stats` never exceeded ~101% CPU across a full 1-hour run with
  8 host cores available.

**Fix:** set explicitly, e.g. `OPENROAD_THREADS: 8`, `STA_THREADS: 9`
(one per PVT corner). Confirmed effect on this design: wall time for a
full flow dropped from ~62 min (1 thread) to ~21 min (8 threads) -- CPU
usage during multi-threaded stages hit ~796% (basically all 8 cores).
**Always set these explicitly before a cloud burst -- do not trust the
"auto-detects core count" documentation.**

### 2. `SYNTH_STRATEGY` defaults to `"AREA 0"` (area-optimized, not timing)
For a real, non-trivial core, the default area-first strategy leaves
real setup-timing slack on the table. Switching to `SYNTH_STRATEGY:
"DELAY 4"` (the most aggressive delay-optimized ABC strategy) measurably
improved timing closure on picorv32 at a *tighter* clock than the
default strategy achieved at a looser one:
- `AREA 0` @ 30ns: worst setup slack -3.09ns (11 violations)
- `DELAY 4` @ 25ns: worst setup slack -2.16ns (3 violations) -- better
  result at a 5ns tighter target
- `DELAY 4` @ 30ns: worst setup slack **+2.79ns, 0 violations** -- clean

**Try a DELAY strategy before reaching for a slower clock** on any
design where the default AREA strategy leaves setup violations.

### 3. Explicit slew/cap repair margins can OOM-kill OpenROAD on larger designs
`designs/uart`'s signoff gotcha
(`wiki/uart-signoff-sizing-and-slew-margin.md`) fixed residual max-slew
violations via `DESIGN_REPAIR_MAX_SLEW_PCT`/`GRT_DESIGN_REPAIR_MAX_SLEW_PCT`.
The same mechanism, applied to picorv32 (19k instances, 6316 nets needing
repair), **reproducibly OOM-killed the OpenROAD process** on a 23GB
local machine -- confirmed via kernel log:
```
Out of memory: Killed process ... (openroad) total-vm:26842284kB, anon-rss:20885252kB
```
i.e. ~20GB resident just for this one repair step. This happened
**identically regardless of `OPENROAD_THREADS`** (crashed the same way
at 8 threads and at 4 threads) -- ruling out a threading bug and
confirming a genuine per-design-size memory requirement for this
specific repair pass, not something `OPENROAD_THREADS` controls.

**Implication for sizing a cloud run:** don't assume the "unfixed
slew/cap violations" residual on a design this size is cheap to chase --
budget real RAM headroom (this alone wanted ~20GB on top of everything
else) before attempting it, and don't try to fix it on a laptop-class
machine. This is exactly the kind of empirical data point kickoff doc
§5.2's RAM sizing guess needed and didn't have.

## Search Shortcuts
- Grep: `OPENROAD_THREADS`, `STA_THREADS`, `SYNTH_STRATEGY`,
  `DESIGN_REPAIR_MAX_SLEW_PCT`, `ORD-0032`
- Dir: `designs/picorv32/config.yaml`, `designs/*/runs/*/32-openroad-repairdesignpostgpl/`
- Kernel OOM evidence: `journalctl -k --since "<time>" | grep -i "out of memory"`

## Gotchas
- The OOM crash's own LibreLane-level error message ("OpenROAD.RepairDesignPostGPL
  failed with an unexpected error... file an issue") gives **no hint**
  that the real cause is OOM -- you have to go to the kernel log
  (`journalctl -k` / `dmesg`) to find the actual `Killed process ...
  (openroad)` line. Don't assume "unexpected error" from LibreLane means
  a tool bug worth filing upstream without checking OOM first.
- A design that closes timing "cleanly" per `flow__errors__count == 0`
  can still have thousands of unrepaired max-slew/max-cap violations in
  `metrics.json` (`design__max_slew_violation__count`) -- the flow does
  not treat these as fatal the way it does setup/hold violations. Always
  check these counts explicitly, don't infer "clean" from exit code
  alone.
