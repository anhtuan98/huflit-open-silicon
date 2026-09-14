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

## In progress

- Creating the public GitHub remote (ADR-OS-004) now that the lead is
  confirmed — thầy is doing this now; see Next/TODO for what's left to wire
  up on this side once the remote exists.

## Next / TODO

- [ ] **thầy:** create the public GitHub repo, then hand the remote URL back
  so it can be wired up (`git remote add origin ...` + push `main`).
- [ ] Decide time-protection mechanism for the lead role (reduced teaching
  load or stipend) — still open, kickoff doc §11.
- [ ] `docker/Dockerfile` and `docker/docker-compose.yml` still track the
  floating `hpretl/iic-osic-tools:latest` tag. Confirmed working today
  (2026-09-14, amd64) and confirmed the image also publishes native `arm64`
  (Apple Silicon) — but `latest` is still not a reproducible pin. Switch to
  a dated tag (e.g. `year.month`, see the image's own tag scheme on Docker
  Hub) once the Phase 0 lead is set up, so their environment is byte-for-byte
  reproducible from day one.
- [ ] Once a real design is chosen for kickoff doc §4 week 3-6 (own
  counter/UART, not the bundled `spm` example), replace the ad-hoc
  `tmp/spm_example/` run with a proper `designs/<name>/` entry.
- [ ] Shortlist 10 candidate open-source IPs for the first PR target (kickoff
  doc §11).
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
  `verification/` have real content (nothing to run yet).

## Decisions & context

- Program codename is **Vega** (see `brainstorming/code_naming_guide.md`);
  the sibling hardware repo is `altair`.
- Full rationale for scope, ADRs, and stage gates: `docs/OPEN_SILICON_KICKOFF.md`.
  Anything that changes from that baseline gets logged in
  `PROJECT_INSTRUCTIONS.md`, not rewritten here.
- Non-goals are load-bearing: no department, no lab, no equipment purchase,
  no tape-out, no press, in the first 12 months. See kickoff doc §1.2.
