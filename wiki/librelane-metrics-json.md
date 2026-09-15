---
sources: [designs/counter3/runs/*/final/metrics.json, designs/counter3/runs/*/flow.log]
related: [[librelane-config-for-tiny-designs]]
created: 2026-09-15
updated: 2026-09-15
---

# Reading LibreLane's `final/metrics.json`

## Entry Points
- `designs/<name>/runs/<RUN_ID>/final/metrics.json` -- one flat JSON object,
  hundreds of keys, produced by the last flow stage. Not committed (see
  `.gitignore`) -- regenerate by re-running the flow.
- `designs/<name>/runs/<RUN_ID>/flow.log` -- human-readable stage-by-stage
  log; the signoff checkers (`Checker.XOR`, `Checker.MagicDRC`,
  `Checker.LVS`, `Checker.SetupViolations`, etc.) print one plain-English
  "clear" or "N violations found" line each, easier to scan than hunting
  the equivalent `*__count` keys in the JSON.

## Key Patterns
- `design__instance__count` (total placed instances) is **not** simply
  `stdcell + fill + tap`. On `counter3`'s signoff run it equalled
  `design__instance__count__stdcell` (112) + `design__instance__count__class:fill_cell`
  (616) = 728 exactly; tap cells (90) were tracked separately and were not
  part of that total. Don't assume this decomposition holds on every
  design/version -- verify the arithmetic on the actual `metrics.json`
  before quoting a breakdown in a report.
- Power keys (`power__internal__total`, `power__switching__total`,
  `power__leakage__total`, `power__total`) are in **mW**. Convert to nW by
  multiplying by 1e6 -- easy to get the exponent wrong when a tiny design's
  power is already like `9.7e-05`.
- Timing keys are reported per PVT corner (suffix
  `__corner:nom_tt_025C_1v80` etc.) *and* as an unsuffixed overall
  worst-across-all-corners value. The unsuffixed `timing__setup__ws` /
  `timing__hold__ws` are the ones worth quoting as "the" result.
- Stage count: count the numbered directories under a `RUN_*/` folder
  (`ls -d [0-9]*`) -- `counter3`'s successful run had 76, not the
  round "80" figure quoted from memory in `backlog.md`'s first-pass note.
  Trust the actual run directory over a remembered number.

## Search Shortcuts
- Grep: `design__instance__count`, `power__total`, `timing__setup__ws`,
  `timing__hold__ws`
- Dir: `designs/*/runs/*/final/metrics.json`, `designs/*/runs/*/flow.log`

## Gotchas
- `metrics.json` contains literal `Infinity` values (e.g.
  `timing__setup_r2r__ws`) for corners with no reg-to-reg path to measure
  -- valid JSON5-ish output from the tool, but not standard JSON; a strict
  `json.load` in Python handles it fine (Python's json module accepts
  `Infinity` by default), but don't assume every JSON parser will.
