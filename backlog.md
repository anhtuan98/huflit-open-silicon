# Backlog — Vega / HUFLIT Open Silicon

## Done

- Repository scaffold created per `docs/OPEN_SILICON_KICKOFF.md` §6 (2026-09-14):
  `docs/` (+ `decisions/`, `vi/`), `designs/`, `verification/`, `docker/`,
  `.github/workflows/`, `wiki/`, plus `README.md`, `PROJECT_INSTRUCTIONS.md`,
  `CHANGELOG.md`, `.env.example`, `.gitignore`, `.dockerignore`,
  `.pre-commit-config.yaml`.
- Six starting ADRs (ADR-OS-001..006) transcribed from kickoff doc §7 into
  `docs/decisions/` as individual files.
- Local git repo initialized (no remote yet, no commit made — see Next/TODO).

## In progress

- Nothing in progress. Phase 0 is blocked on finding a lead (see Known issues).

## Next / TODO

- [ ] **Blocking everything else:** identify the Phase 0 lead (young lecturer
  or strong final-year student, good English reading, stubborn; no chip
  background required). See kickoff doc §11 and §4 Giai đoạn 0.
- [ ] Decide time-protection mechanism for that person (reduced teaching load
  or stipend).
- [ ] Review and commit the initial scaffold (`git add` + first commit) once
  thầy has reviewed the content.
- [ ] Decide repo host: default is GitHub (public, per ADR-OS-004) — create
  the remote once the lead is confirmed, not before (avoid premature movement
  per kickoff doc §1.2).
- [ ] Pin the exact IIC-OSIC-TOOLS image tag in `docker/Dockerfile` and
  `docker/docker-compose.yml` — currently a placeholder, needs verification
  against `github.com/iic-jku/IIC-OSIC-TOOLS` before first use.
- [ ] Shortlist 10 candidate open-source IPs for the first PR target (kickoff
  doc §11).
- [ ] Verify Efinix EULA before publishing any findings about their tooling
  (kickoff doc §11) — only relevant if/when Efinix tooling is touched.

## Known issues & gotchas

- No lead identified yet for Phase 0 — this is the true bottleneck, not
  funding or tooling. Do not start any other workstream until this is
  resolved (kickoff doc §10).
- `docker/docker-compose.yml` references an unpinned IIC-OSIC-TOOLS image tag;
  do not rely on it for a reproducible build yet.
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
