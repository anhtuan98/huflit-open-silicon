# Runbook — Vega / HUFLIT Open Silicon

Phase 0 has no server, no CI infra beyond linting, and no production deploy —
this runbook only covers the local reproducible tool environment and the
smoke test called out in `docs/OPEN_SILICON_KICKOFF.md` §4 (weeks 1-2).

## 1. Local environment (Docker, IIC-OSIC-TOOLS)

```bash
# from repo root
docker compose -f docker/docker-compose.yml build
docker compose -f docker/docker-compose.yml run --rm librelane-dev bash
```

This drops you into a shell inside the toolchain container with the repo
mounted at `/workspace`.

**Before first use:** the image tag in `docker/Dockerfile` is a placeholder.
Verify the current recommended tag against
`github.com/iic-jku/IIC-OSIC-TOOLS` and pin it explicitly — do not build
against a floating tag.

## 2. Smoke test (week 1-2 deliverable)

Inside the container:

```bash
librelane --smoke-test
```

Expected output: one GDSII file produced from LibreLane's built-in smoke
design. This is the required output for kickoff doc §4 week 1-2 — it proves
the toolchain runs end to end, nothing more.

## 3. First real design (week 3-6)

Run a small self-written design (counter / UART) through the full
RTL -> GDSII flow with DRC, LVS, and timing sign-off. Put the RTL under
`designs/<design_name>/`, the LibreLane config alongside it. Goal is
understanding *why sign-off is the hard part* — not tape-out (see
ADR-OS-003). No shuttle submission.

## 4. Verification (week 7-12 and onward — the actual product)

cocotb testbenches live in `verification/`. Pick an open-source IP missing
verification coverage, write a testbench, find a real bug, send a PR
upstream. One merged PR is Gate 0 (see `PROJECT_INSTRUCTIONS.md`).

## 5. Regression / ECC-of-the-poor-man's check

Once there is a regression server (not before Phase 1, see kickoff doc
§5.2), add a weekly CI job that runs the same design twice and diffs the
GDS hash. A mismatch means something is wrong — this also catches software
bugs, not just hardware memory errors.

## 6. Rollback / recovery

Nothing is deployed anywhere yet, so there is no production rollback
procedure. This section gets filled in only when Phase 1/2 introduces a
regression server (kickoff doc §5.2) — do not build it prematurely.
