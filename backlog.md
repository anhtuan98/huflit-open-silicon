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
- **apb_timer PR drafted (2026-09-15):** issue #7 (`TIMER_CNT=1` build
  failure) root-caused, fixed, and regression-tested. Commits local-only
  in `tmp/apb_timer/` (`2e177fe`, `68e7471`, not pushed), PR title/body
  drafted in `tmp/apb_timer/PR_DESCRIPTION.md`. Blocked only on thầy
  forking the upstream repo and pushing (no GitHub write access from
  this session).
- **Linode cloud-burst mechanics validated end-to-end (2026-09-16):**
  full rehearsal on a Nano instance (1 vCPU/1GB RAM/25GB disk,
  `172.104.57.135`) using `counter3` as a lightweight stand-in payload:
  SSH (key-based), scp upload (not git clone, per thầy's preference),
  Docker install, pinned-image build (3.76GB compressed / 16GB on disk --
  watch this on small disks), full LibreLane flow (76/76 stages, clean
  signoff, 5m45s even on 1 vCPU/1GB RAM), and the
  `/home/natuan/outputs` file-location convention thầy set. Confirmed
  pip is unavailable/unused on this VM by design (apt-only) and none of
  the cloud-burst scripts need it. `docker/cloud-burst/telegram_notify.sh`
  added for milestone alerts (bootstrap done, early finish, time-limit
  checkpoint) -- needs a bot token from thầy (via @BotFather) before it
  can actually send anything, degrades to local-log-only otherwise.
  Key operational decision from thầy: **resize this same instance
  in-place** (Linode supports this) rather than create a new VM for the
  real run -- Docker/images/files all survive a resize since it's the
  same disk, no re-bootstrap needed, just confirm disk auto-expanded
  after resize (`growpart`/`resize2fs` if not) before the real run.
- **picorv32 local fine-tuning, 8 rounds (2026-09-16, overnight per
  thầy's request while he slept):** designs/picorv32/ (YosysHQ picorv32
  core, ISC license, ~19k instances -- first design at this scale in the
  repo) taken through repeated local LibreLane iterations on this 8-core
  laptop, specifically to de-risk the config AND generate real
  resource-sizing data before spending on the cloud VM. Three concrete,
  wiki-documented findings (`wiki/librelane-threading-and-timing-strategy.md`):
  (1) `OPENROAD_THREADS`/`STA_THREADS` must be set explicitly -- silently
  fall back to 1 thread despite docs claiming auto-detect (fixing this
  cut a full-flow run from ~62min to ~21min on 8 cores); (2)
  `SYNTH_STRATEGY: "DELAY 4"` beats the default `"AREA 0"` for timing
  closure on a real core; (3) applying uart's own slew-margin fix
  (`DESIGN_REPAIR_MAX_SLEW_PCT`) at this design's scale reproducibly
  OOM-killed OpenROAD (~20GB RSS, confirmed via `journalctl -k`),
  independent of thread count -- a real RAM ceiling, not a bug, and
  direct empirical evidence for kickoff doc §5.2's RAM-sizing question.
  **Best clean result achieved** (`designs/picorv32/config.yaml` as
  currently committed-ready, `CLOCK_PERIOD: 30` / `SYNTH_STRATEGY: "DELAY
  4"` / explicit threads): 76/76 stages, **0 setup/hold violations**
  (worst slack +2.79ns), DRC/LVS/antenna/XOR all clean, reproduced
  identically on a second run (bonus: informal determinism confirmation).
  **Not yet fully clean:** 2837 max-slew + 31 max-cap violations remain
  unrepaired -- fixing them is exactly the kind of task that needs the
  cloud machine's RAM, not something to keep chasing locally. GDSII
  preserved (not committed -- gitignored `runs/`, per convention).
- **`picorv32` technical report written (2026-09-17):**
  `docs/picorv32-technical-report.md` -- full attempt-by-attempt
  narrative of all 9 local rounds (§5 of that doc), including the
  process mistake of losing attempt 5's artifacts to an `rm -rf`
  before preserving them (had to be regenerated as attempt 9), and an
  explicit, unresolved anomaly (why attempts 1-2's *less* negative
  setup slack triggered LibreLane's hard-quit path while attempt 3's
  *worse* slack did not). Answers thầy's question about whether this
  work is publication-worthy directly in the report's own §1: not as a
  `picorv32` contribution (no bug found, no PR possible), but yes as a
  public technical article on LibreLane's own behavior at this design
  scale -- and the threading auto-detect gap (§6.1) is separately
  worth filing as a `librelane/librelane` issue, independent of the
  article.
- **picorv32 report: Vietnamese adaptation + LibreLane issue drafted
  (2026-09-17):** thầy confirmed both, citing Vietnamese students as the
  primary audience but English as necessary for international
  reputation-building. Vietnamese: `docs/vi/picorv32-bao-cao-ky-thuat.md`
  (full 9-attempt narrative, same honesty about the unresolved anomaly
  and the lost-artifact mistake, plus a supplementary EN-VI glossary).
  Issue draft for `librelane/librelane` (the §6.1 threading auto-detect
  gap): `tmp/librelane-thread-issue.md` -- not posted, needs thầy's
  GitHub account.
- **ORConf 2026 program reviewed for 2027 submission planning
  (2026-09-18):** pulled the real 73-talk program (not just the landing
  page) directly from the conference site's embedded data. Full notes,
  curated relevant-talk list, and 2027 pitch ideas in
  `brainstorming/orconf-2026-review-and-2027-plan.md` (gitignored, internal
  only). Confirmed a genuine gap worth exploiting: **no 2026 talk covered
  Southeast Asia or language localization** -- backs up kickoff doc §9's
  prediction about the Vietnamese-localization talk angle. Also flagged
  two tools to watch (`EDABench` -- ML integrated into LibreLane itself;
  `RVVTS` -- RISC-V ISA-extension bug-hunting framework) as directly
  relevant to this program's own toolchain, independent of any conference
  submission.
- **Teaching material: full RTL-to-GDSII flow explainer + cocotb
  walkthrough written (2026-09-18/19),** prompted by thầy asking to
  understand the whole flow and how to write a cocotb testbench, using
  `counter3` as the concrete example throughout. Four files, EN original +
  VI adaptation each (per `docs/vi/` purpose #2):
  `docs/chip_making_a_to_z.md` / `docs/vi/chip-making-a-to-z.md` (what
  each of the ~9 conceptual stages does, where LibreLane's 76 sub-stages
  fit, the two-different-meanings-of-"verify" distinction thầy asked
  about specifically, what GDSII actually is, what tape-out means and why
  this program hasn't done it yet); `docs/cocotb-testbench-guide.md` /
  `docs/vi/cocotb-huong-dan-viet-testbench.md` (line-by-line walkthrough
  of `test_counter3.py` -- `dut` handle, `Clock`/`start_soon` vs. `await`,
  `RisingEdge`, relative-vs-absolute assertions, plus a suggested
  practice exercise: add a mid-count reset test). Both explicitly tie
  back to why this matters for the program: this is the exact skill set
  Gate 0 needs on `obi_uart`.
- **`.gitignore` fixed (2026-09-19):** `brainstorming/` was only excluding
  one specific file (`code_naming_guide.md`), not the whole directory --
  two more untracked, internal-only files (the budget proposal, the
  ORConf notes above) were sitting unprotected and would have been swept
  into a broad `git add`. Now the whole directory is ignored, matching
  the intent already stated in `CLAUDE.md` and in the budget proposal's
  own header.

## In progress

- **Gate 0 target chosen: `obi_uart`** (`pulp-platform/obi_peripherals`) —
  a UART peripheral with only a single directed SystemVerilog testbench
  and **no cocotb coverage at all** (confirmed via the repo's own commit
  history, most recently active 2026-08-24). See Decisions & context for
  why this one over the others found.
  - **Maintainer replied on PR #9 (2026-09-15, `phsauter`,
    [comment](https://github.com/pulp-platform/obi_peripherals/pull/9#issuecomment-5678713911)):**
    confirms the register interface is **not** stable yet -- "there is
    actually one further change that needs to be done downstream of
    this," targeted "this week." Reason for the delay: they test against
    real hardware, not just simulation -- `obi_uart` is validated as part
    of the **Cheshire SoC on FPGA** with multiple UART devices on the
    other side, which takes time to run. Two things to take from this:
    (a) fast, substantive maintainer response on day 0 -- strong signal
    this is a well-run, responsive project, good sign for a first PR
    landing here; (b) **still blocked** -- don't start the testbench
    against the current register interface, it's about to change. No
    reply yet on the separate cocotb-acceptance issue.
  - Next check-in: revisit in ~1 week (thầy to ping, or check the PR/issue
    directly) rather than polling.
- **Linode Nano VM `172.104.57.135` being deleted (2026-09-17), plan to
  resize it changed.** Thầy decided to delete the rehearsal VM to stop
  paying for it, rather than resize it in-place as previously planned.
  Confirmed via SSH (`natuan@172.104.57.135`, still Nano: 1 vCPU/~1GB RAM,
  25GB disk 80% full) that the real `picorv32` burst had **not** started
  on it yet -- only the `counter3` rehearsal payload was on there, so no
  picorv32 data was at risk. Before deletion, rsync'd the real data (76MB:
  configs, Verilog source, cocotb/LibreLane logs, the rehearsal's signed-off
  GDSII in 3 formats) to `tmp/linode_172.104.57.135_backup/` (gitignored,
  local only) -- deliberately skipped the 16GB-on-disk Docker image
  (`docker-librelane-dev:latest`, rebuildable from `docker/Dockerfile`) and
  the VM's own system dirs (`.ssh`/`.docker`/`.config`/`.cache`). Thầy is
  deleting the VM himself via the Linode dashboard/API (declined to give
  this session delete access). **Still open:** the real `picorv32` burst
  (fix remaining slew/cap violations + N-way determinism check) now has no
  VM to run on -- next cloud-burst attempt needs a fresh VM provisioned
  first. `docker/cloud-burst/` scripts still need the consolidation pass
  noted in Known issues below regardless of which VM they eventually run on.

## Next / TODO

- [ ] **thầy is actively learning the RTL-to-GDSII flow and cocotb
  testbench writing** (started 2026-09-18/19, reference material:
  `docs/chip_making_a_to_z.md`, `docs/cocotb-testbench-guide.md` and their
  `docs/vi/` counterparts). Next session: don't assume this is done after
  one read-through -- check in on whether thầy did the suggested
  `counter3` mid-count-reset exercise (`docs/cocotb-testbench-guide.md`
  §4), review what he wrote, and keep answering follow-up "why" questions
  about the flow until he can read/write a testbench without needing the
  basic concepts re-explained. This is direct preparation for writing the
  `obi_uart` testbench (Gate 0) -- treat it as a prerequisite
  skill-building thread, not a one-off Q&A.
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
- **`OPENROAD_THREADS`/`STA_THREADS` silently default to 1 thread**
  despite documentation claiming auto-detect of the machine's core
  count; **`SYNTH_STRATEGY` defaults to area-optimized, not timing**; and
  the uart-style slew-margin repair fix can **OOM-kill OpenROAD** on a
  ~19k-instance design regardless of thread count (~20GB RSS observed).
  Full detail: `wiki/librelane-threading-and-timing-strategy.md`.
- **`docker/cloud-burst/` has duplicate/overlapping scripts** from two
  different authors (a background agent's own initiative plus the
  parent session, working in parallel without realizing it) --
  `bootstrap.sh`, `driver.sh`, `retrieve.sh`, `retrieve_results.sh`,
  `bundle_results.py`, `telegram_notify.sh` all coexist, not all
  mutually consistent (e.g. git-clone-based vs. thầy's actual
  scp-based approach). Needs one consolidation pass before it's handed
  to thầy as "the" script to run on the resized VM -- don't just pick
  one file at random, read all of them first.

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
- **ADR-OS-007 (2026-09-16): rent cloud compute by the hour, don't buy
  server hardware, until the program is financially self-sustaining.**
  Prompted by the `picorv32` cloud-burst plan (Linode, see below) --
  thầy's own framing: renting saves upfront capex and maintenance during
  the early, personnel-risk-heavy phase; revisit buying dedicated
  regression hardware once the program can afford it on its own revenue.
  Full rationale: `docs/decisions/ADR-OS-007-rent-compute-before-buying.md`.
