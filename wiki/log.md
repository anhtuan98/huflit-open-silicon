# Wiki Log

| Date | Action | Article | Reason |
|---|---|---|---|
| 2026-09-14 | init | - | Scaffolded wiki/ (index.md, log.md, TEMPLATE.md) for new repo. No JS-1 bootstrap performed -- no git history / merged PRs exist yet. |
| 2026-09-14 | learn | librelane-config-for-tiny-designs | Debugged counter3's LibreLane run through 3 failure modes (wrong ambient PDK, PDN-0185, DPL-0036) across several iterations; worth saving so the next design doesn't repeat the same trial-and-error. |
| 2026-09-14 | learn | docker-toolchain-invocation | Same session: --skip flag and --workdir override for the IIC-OSIC-TOOLS container weren't obvious from --help alone. |
| 2026-09-15 | learn | librelane-metrics-json | Writing the counter3 technical report/slides required reconciling metrics.json's instance-count breakdown and unit conventions (power in mW) against flow.log -- also caught backlog.md's earlier "80 stages" note being off (actual: 76), worth flagging for next design write-up. |
| 2026-09-15 | learn | uart-signoff-sizing-and-slew-margin | Building designs/uart/: confirmed counter3's floorplan/PDN tuning is NOT needed once a design is past ~50 sequential cells (default sizing worked); hit a new, unrelated post-route max-slew violation at the ss corner only, fixed via DESIGN_REPAIR_MAX_SLEW_PCT/GRT_DESIGN_REPAIR_MAX_SLEW_PCT margin widening. Also found the MaxSlewViolations checker step logs a contradictory WARNING+VERBOSE pair when violations exist. |
