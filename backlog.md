# Backlog — Vega / HUFLIT Open Silicon

## Done

- Repository scaffold created per `docs/OPEN_SILICON_KICKOFF.md` §6 (2026-09-14):
  `docs/` (+ `decisions/`, `vi/`), `designs/`, `verification/`, `docker/`,
  `.github/workflows/`, `wiki/`, plus `README.md`, `PROJECT_INSTRUCTIONS.md`,
  `CHANGELOG.md`, `.env.example`, `.gitignore`, `.dockerignore`,
  `.pre-commit-config.yaml`.
- Six starting ADRs (ADR-OS-001..006) transcribed from kickoff doc §7 into
  `docs/decisions/` as individual files.
- Local git repo initialized and first commit made (2026-09-14, `966bae4`,
  local identity Tuan Nguyen / tuanna@huflit.edu.vn — no remote yet).
- `tmp/` scratch directory added (gitignored except `.gitkeep`) per thầy's
  instruction — used for local cache/temp files, never the Artifact tool.
- **Kickoff doc §4 Giai đoạn 0, week 1-2 deliverable done (2026-09-14):**
  `docker compose -f docker/docker-compose.yml build` pulled/built
  `hpretl/iic-osic-tools:latest` successfully on this Ubuntu machine (amd64).
  `librelane --version` → LibreLane v3.1.0.dev3. `librelane --smoke-test`
  passed (Antenna/LVS/DRC all Passed) — note this subcommand's output is
  intentionally temporary/discarded by design, not a bug. To satisfy the
  literal "một file GDSII" deliverable, additionally ran the bundled `spm`
  example end-to-end (`librelane --run-example spm`, working dir
  `tmp/spm_example/`) — full Classic flow, all 80 stages, Antenna/LVS/DRC
  Passed, GDSII files produced and persisted locally at
  `tmp/spm_example/spm/runs/RUN_2026-09-14_16-38-49/final/gds/spm.gds`
  (and `.klayout.gds`, `.magic.gds` variants). These are gitignored — local
  evidence only, not committed (`tmp/` is scratch, not a deliverable store).
- **Phase 0 lead confirmed (2026-09-14): Nguyễn Anh Tuấn.** The single
  blocking item from kickoff doc §11 is resolved — see
  `PROJECT_INSTRUCTIONS.md`. Gate 0 clock (1 merged PR within 90 days) starts
  today.
- **Public GitHub repo live (2026-09-14):**
  `github.com/anhtuan98/huflit-open-silicon`, Apache-2.0. History was
  squashed once early on (repo was public <5 min with no other clones) to
  drop an internal cross-project naming-notes file that got committed by
  mistake — clean from commit `f6a6259` onward. `tmp/` and
  `brainstorming/code_naming_guide.md` are gitignored so this can't recur.
- **Kickoff doc §4 Giai đoạn 0, week 3-6 deliverable done (2026-09-14):**
  own design (not a bundled example) run trọn RTL→GDSII with full DRC/LVS/
  timing sign-off. `designs/counter3/` — a 3-bit synchronous up-counter
  (`src/counter3.v`), cocotb testbench (`verify/`, 2/2 tests passing via
  Verilator), LibreLane `config.yaml`. Full Classic flow 80/80 stages,
  Antenna/LVS/DRC all Passed, no setup/hold/slew/cap violations. GDSII at
  `designs/counter3/runs/RUN_2026-09-14_18-09-59/final/gds/counter3.gds`
  (gitignored — `runs/` regenerates from `config.yaml`, not committed, per
  "reproducible from Git" — commit the config, not the binary output).

## In progress

- Nothing in progress. `counter3` is the first of possibly more small
  learning designs (UART is the other one kickoff doc §4 names) before
  moving to week 7-12 (pick an upstream IP, write a cocotb testbench, get a
  PR merged -- the actual Gate 0 deliverable).

## Next / TODO

- [ ] Decide time-protection mechanism for the lead role (reduced teaching
  load or stipend) — still open, kickoff doc §11.
- [ ] `docker/Dockerfile` and `docker/docker-compose.yml` still track the
  floating `hpretl/iic-osic-tools:latest` tag. Confirmed working today
  (2026-09-14, amd64) and confirmed the image also publishes native `arm64`
  (Apple Silicon) — but `latest` is still not a reproducible pin. Switch to
  a dated tag (e.g. `year.month`, see the image's own tag scheme on Docker
  Hub) once the Phase 0 lead is set up, so their environment is byte-for-byte
  reproducible from day one.
- [ ] Kickoff doc §4 week 3-6 is technically satisfiable with just
  `counter3`, but a UART would exercise more of the flow (multi-clock-domain
  thinking, more cells) if there's time before moving to week 7-12.
- [ ] Shortlist 10 candidate open-source IPs for the first PR target (kickoff
  doc §11) — this is the actual next milestone (week 7-12, Gate 0).
- [ ] Verify Efinix EULA before publishing any findings about their tooling
  (kickoff doc §11) — only relevant if/when Efinix tooling is touched.

## Known issues & gotchas

- `docker/docker-compose.yml` references the floating `:latest` IIC-OSIC-TOOLS
  tag — confirmed functional (2026-09-14) but not yet pinned, so don't treat
  today's environment as byte-for-byte reproducible until it is (see TODO).
- The IIC-OSIC-TOOLS image entrypoint is not a plain shell: it expects
  `--skip` (or `-s`) as the **first** argument to bypass its VNC/X11 UI
  startup and run a command directly, e.g.
  `docker compose run --rm librelane-dev --skip librelane --smoke-test`.
  Without `--skip` it just prints usage and exits.
- `librelane --smoke-test` deliberately discards its run directory on exit
  (confirmed via `librelane --help`: "results ... are temporary and
  discarded") — this is correct behavior for a toolchain sanity check, not
  something to work around for that command. To get a persisted GDSII, use
  `librelane --run-example <name>` (e.g. `spm`) instead, with `--workdir`
  pointed at a mounted host directory.
- CI workflow (`.github/workflows/ci.yml`) only lints Markdown for now — the
  simulate/LibreLane/hash-compare stages are stubs until `designs/` and
  `verification/` have real content (there is now a real design at
  `designs/counter3/` -- still not wired into CI, since a full PnR run is
  too slow/heavy for a CI runner without more thought about caching).
- **The IIC-OSIC-TOOLS container's ambient default PDK is `ihp-sg13g2`**
  (`$PDK` env var inside the container), not `sky130A`, even though a
  design's `config.yaml` sets `pdk::sky130*:` overrides. Those overrides are
  silently ignored if the wrong PDK is active. Always pass `-p sky130A -s
  sky130_fd_sc_hd` explicitly on the `librelane` command line for a sky130
  design -- don't rely on the ambient default. (Discovered running
  `designs/counter3` — first attempt read IHP timing libs despite the
  config's sky130 block.)
- **A design as small as a 3-bit counter needs explicit floorplan/PDN
  tuning** — percentage-based sizing (`FP_CORE_UTIL`) computes too small an
  absolute die for a handful of cells once PDN straps and post-CTS hold
  buffers need room: `PDN-0185` (insufficient strap width) at the PDN stage,
  then `DPL-0036` (detailed placement failed) after hold-fixing if you patch
  only the first one. Fix: `FP_SIZING: absolute` + an explicit `DIE_AREA`
  (as a YAML list, e.g. `[0, 0, 100, 100]` -- a quoted string is rejected:
  "Refusing to automatically convert string at 'DIE_AREA' to list"), plus
  the same `PDN_V/HOFFSET`, `PDN_V/HWIDTH`, `PDN_V/HPITCH`,
  `PDN_SKIPTRIM: true` block LibreLane's own bundled `spm` example uses for
  the same reason. See `designs/counter3/config.yaml` for a working example.
- **cocotb + Verilator: writing a signal's `.value` right after `await
  RisingEdge(...)` is not guaranteed visible to the DUT on the very next
  edge** — deasserting `rst` this way took an extra cycle to be observed in
  `designs/counter3/verify/test_counter3.py`, off-by-one-failing a test that
  hardcoded "count == 1 on the first post-reset cycle". Not a RTL bug. Fix
  used: write the test's expectations relative to the previous observed
  cycle (self-referential), not to an absolute cycle count tied to exactly
  when a deasserted reset is presumed to take effect.

## Decisions & context

- Program codename is **Vega** (see `brainstorming/code_naming_guide.md`);
  the sibling hardware repo is `altair`.
- Full rationale for scope, ADRs, and stage gates: `docs/OPEN_SILICON_KICKOFF.md`.
  Anything that changes from that baseline gets logged in
  `PROJECT_INSTRUCTIONS.md`, not rewritten here.
- Non-goals are load-bearing: no department, no lab, no equipment purchase,
  no tape-out, no press, in the first 12 months. See kickoff doc §1.2.
