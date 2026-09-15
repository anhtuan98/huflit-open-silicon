---
sources: [designs/counter3/config.yaml, docker/Dockerfile, docker/docker-compose.yml]
related: [[docker-toolchain-invocation]]
created: 2026-09-14
updated: 2026-09-14
---

# LibreLane Config for Tiny Designs

## Entry Points
- `designs/counter3/config.yaml` -- working reference config for a ~10-20
  cell design (3-bit counter), annotated with why each non-default key
  exists.
- LibreLane's own bundled `spm` example (inside the container, not this
  repo): `/usr/local/lib/python3.12/dist-packages/librelane/examples/spm/`
  -- hits the same PDN problem for the same reason (also a tiny design).

## Key Patterns
- The IIC-OSIC-TOOLS container's **ambient default PDK is `ihp-sg13g2`**
  (`$PDK` env var), not `sky130A`. A `config.yaml`'s `pdk::sky130*:` block is
  silently a no-op if the wrong PDK is active -- it never errors, it just
  never applies. Always pass explicitly on the CLI:
  `librelane -p sky130A -s sky130_fd_sc_hd config.yaml`.
- A design this small breaks LibreLane's percentage-based floorplan sizing
  (`FP_CORE_UTIL`): the absolute die it computes is too small once PDN
  straps and post-CTS hold buffers need room. Symptoms, in the order you'll
  hit them if you only fix one at a time:
  1. `PDN-0185` "Insufficient width to add straps" at the PDN generation
     stage.
  2. `DPL-0036` "Detailed placement failed" later, at post-CTS resizer
     timing (hold-buffer insertion has nowhere legal to place buffers).
- Fix for both: `FP_SIZING: absolute` + an explicit `DIE_AREA` (generous
  headroom, e.g. `[0, 0, 100, 100]` in microns for a handful of cells), plus
  the PDN tuning block (`PDN_VOFFSET`, `PDN_HOFFSET`, `PDN_VWIDTH`,
  `PDN_HWIDTH`, `PDN_VPITCH`, `PDN_HPITCH`, `PDN_SKIPTRIM: true`) -- same
  values as the bundled `spm` example.
- `DIE_AREA` must be a YAML **list** (`[0, 0, 100, 100]`), not a quoted
  string -- a string is explicitly rejected: "Refusing to automatically
  convert string at 'DIE_AREA' to list".

## Search Shortcuts
- Grep: `FP_SIZING`, `DIE_AREA`, `PDN_SKIPTRIM`, `PDN-0185`, `DPL-0036`
- Dir: `designs/*/config.yaml`
- Don't grep: `PDN` alone (too broad, matches every PDN_* key)

## Gotchas
- This whole class of problem only shows up on genuinely tiny designs (a
  handful of flip-flops/gates). A design with hundreds of cells (like
  `spm`) needs the PDN tuning but not necessarily the explicit `DIE_AREA`
  override at the same aggressiveness -- don't copy `DIE_AREA` blindly onto
  a bigger design without checking whether it's actually needed.
