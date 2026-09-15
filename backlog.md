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
  Verilator), LibreLane `config.yaml`. Full Classic flow 76/76 stages
  (corrected 2026-09-15 -- an earlier note here said 80, checked against
  the actual run directory while writing the technical report, see
  `docs/counter3-technical-report.md`), Antenna/LVS/DRC all Passed, no
  setup/hold/slew/cap violations. GDSII at
  `designs/counter3/runs/RUN_2026-09-14_18-09-59/final/gds/counter3.gds`
  (gitignored — `runs/` regenerates from `config.yaml`, not committed, per
  "reproducible from Git" — commit the config, not the binary output).
- **counter3 teaching material written (2026-09-15):** technical report
  and slide deck covering the design, verification methodology, LibreLane
  flow, and the three gotchas from the entry above, for use as course
  material. English (primary asset): `docs/counter3-technical-report.md`,
  `docs/counter3-slides.md`. Vietnamese adaptation for HUFLIT students
  (`docs/vi/` purpose #2, includes an EN-VI EDA glossary):
  `docs/vi/counter3-bao-cao-ky-thuat.md`, `docs/vi/counter3-slides.md`.
- **Gate 0 IP shortlist research done (2026-09-15):** three parallel agents
  searched (a) the FOSSi ecosystem itself (cocotb, LibreLane, Embench),
  (b) RISC-V/PULP/OpenHW, (c) general catalogs (OpenCores, LibreCores,
  Tiny Tapeout, CHIPS Alliance, IHP-Open-DesignLib). Screened out as dead
  or wrong-shaped: OpenCores/FreeCores (no activity since 2023), Tiny
  Tapeout (submission model, not a maintained IP with an issue tracker),
  IHP-Open-DesignLib (aggregates one-off tapeout batches, no single-IP
  ownership), `core-v-verif` (UVM-only methodology, cocotb likely won't
  fit), `ibex` (full CPU core, too large), `apb_uart` (logic moved into
  `obi_uart`, now just a wrapper), `librelane/librelane` main repo (open
  issues are flow/tooling bugs, not IP verification gaps). Chosen target
  and watch-list below.
- **UART second learning design done (2026-09-15):** `designs/uart/` —
  independent TX/RX modules, 8N1 framing, built via a background agent in
  an isolated git worktree, reviewed, and merged into `main`. 3/3 cocotb
  tests passing; full LibreLane signoff, 76/76 stages, 0 DRC/LVS/antenna
  errors, 0 timing violations. Unlike `counter3`, needed **no**
  `FP_SIZING: absolute` / PDN tuning (default sizing landed at 75.3%
  utilization on its own) -- confirms that fix is specific to genuinely
  tiny designs, not a general requirement. Did hit one new signoff issue
  (post-route max-slew violations at the `ss` corner only, fixed via
  `DESIGN_REPAIR_MAX_SLEW_PCT`/`GRT_DESIGN_REPAIR_MAX_SLEW_PCT`), written
  up in `wiki/uart-signoff-sizing-and-slew-margin.md`.
- **UART teaching material written (2026-09-15):** technical report and
  slide deck, same structure as the `counter3` pair. English (primary
  asset): `docs/uart-technical-report.md`, `docs/uart-slides.md`.
  Vietnamese adaptation (`docs/vi/` purpose #2, with an additional
  EN-VI glossary for terms not already covered by the counter3 one):
  `docs/vi/uart-bao-cao-ky-thuat.md`, `docs/vi/uart-slides.md`.
- **obi_uart outreach posted (2026-09-15):** thầy posted both the PR #9
  status question (as a comment on
  `pulp-platform/obi_peripherals` PR #9) and the cocotb-acceptance
  question (as a new issue on the repo). Now waiting on a maintainer
  response before writing the testbench.

## In progress

- **Gate 0 target chosen: `obi_uart`** (`pulp-platform/obi_peripherals`) —
  a UART peripheral with only a single directed SystemVerilog testbench
  and **no cocotb coverage at all** (confirmed via the repo's own commit
  history, most recently active 2026-08-24). Outreach posted (see Done
  above) -- blocked on a maintainer response before writing the
  testbench. See Decisions & context for why this one over the others
  found.

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
- [ ] **Check for a maintainer response** on the two `obi_uart` outreach
  posts (see Done, 2026-09-15) -- don't start writing the testbench until
  either gets a reply, per the reasoning already posted (no precedent of
  an external PR merged there yet, and PR #9's register interface may
  still be in flux).
- [ ] **"Nối hướng" the two UART efforts, once outreach clears:** apply
  `designs/uart/verify/test_uart.py`'s byte-framing pattern
  (send/observe start-data-stop bits, loopback checking) to `obi_uart`'s
  actual DUT -- check whether it transfers directly or needs adapting to
  the OBI bus protocol layered on top of the serial pins. See
  `docs/uart-technical-report.md` §7.
- [ ] Watch-list from the shortlist research — worth pursuing later when
  there's spare time, but not the current focus (thầy, 2026-09-15):
  - `apb_timer` (pulp-platform) — zero test scaffolding, but already has
    a confirmed, still-open bug (issue #7: build fails when
    `NUM_TIMERS=1`, a `$clog2` edge case) — the "find a real bug" step is
    already done here, unusually.
  - `chipsalliance/usb2` — NXP-driven, very active, maintainers
    explicitly want more test coverage (issues #5/#7/#13 tagged `[DV]`,
    plus smaller scoped bugs #19/#20) — but it's VHDL/GHDL, not the
    Verilator path used so far, and no external contributor's PR has
    been merged there yet.
  - `librelane/librelane-ci-designs` — thematically the closest match to
    this program (small IPs incl. a UART, used for LibreLane's own CI),
    but the repo is 14+ months stale with zero external-PR precedent —
    treat as a fallback only, not a first choice.
- [ ] Verify Efinix EULA before publishing any findings about their tooling
  (kickoff doc §11) — still open; see the FPGA testbed note in Decisions &
  context below for why this matters now, not just hypothetically.

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
- **FPGA hardware testbed (thầy asked 2026-09-15, re: DE10-Standard,
  Efinix Ti180, and an ULX3S on order from AliExpress):** not needed at
  all for the current Gate 0 work. `obi_uart` verification (like
  `counter3`) is pure cocotb/Verilator simulation -- no board is required
  to write a testbench, find a bug, or get a PR merged. FPGA is a
  separate, optional teaching use case (kickoff doc §5.3: FPGA teaches
  RTL/FSM/testbench/CDC hands-on; it does **not** teach floorplan, PDN,
  CTS, or DRC/LVS/GDSII sign-off -- only LibreLane does, and that needs no
  hardware at all). For that separate use case, if/when it comes up: the
  DE10-Standard (Intel Cyclone V) and Efinix Ti180 both need a proprietary
  toolchain (Quartus, Efinity) to program -- neither has a FOSS flow
  comparable to Yosys+nextpnr+Trellis for the ECP5 -- so featuring either
  in public program material would break the FOSS-first,
  no-proprietary-tooling-required principle (`README.md`, ADR-OS-004).
  Ti180 additionally still has the open Efinix EULA question (kickoff doc
  §11, TODO above) unresolved -- don't publish anything about it before
  that's checked. Recommendation: hold any FPGA teaching track until the
  ULX3S arrives; DE10/Ti180 stay usable for unrelated, non-public purposes
  in the meantime, just not as this program's public FPGA story.
