# Wiki Index — Vega (HUFLIT Open Silicon)

Agent memory for this repo. Hints and pointers only — never answers. See
`wiki/TEMPLATE.md` for article structure and `../wiki-memory` skill for the
read/write protocol.

JS-1 bootstrap (last ~60 merged PRs) does not apply to this repo -- it was
greenfield at scaffold time. Articles below come from real exploration.

## Categories

### Docs & ADRs
<!-- docs/, docs/decisions/, PROJECT_INSTRUCTIONS.md -->

### Designs (RTL -> GDSII)

- [LibreLane Config for Tiny Designs](librelane-config-for-tiny-designs.md)
  FP_SIZING, DIE_AREA, PDN_SKIPTRIM, PDN-0185, DPL-0036, designs/counter3/config.yaml, sky130A, ihp-sg13g2
- [Reading LibreLane's final/metrics.json](librelane-metrics-json.md)
  design__instance__count, power__total units (mW), timing__setup__ws, flow.log checker lines, stage count via `ls -d [0-9]*`
- [uart: Sizing Threshold and Post-Route Slew Margin](uart-signoff-sizing-and-slew-margin.md)
  designs/uart/config.yaml, DESIGN_REPAIR_MAX_SLEW_PCT, GRT_DESIGN_REPAIR_MAX_SLEW_PCT, design__max_slew_violation__count, when default FP_CORE_UTIL sizing is fine vs counter3's FP_SIZING: absolute

### Verification (cocotb / Verilator)
<!-- verification/, testbench conventions per upstream project -->

### Toolchain / Docker

- [Docker Toolchain Invocation (IIC-OSIC-TOOLS)](docker-toolchain-invocation.md)
  --skip, --workdir, cocotb-config --makefiles, librelane --smoke-test, librelane --run-example, docker/docker-compose.yml

### CI/CD
<!-- .github/workflows/, lint -> sim -> LibreLane -> hash pipeline -->

### Localization (docs/vi)
<!-- translation targets, upstream PR status for each translated doc -->
