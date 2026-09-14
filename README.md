# HUFLIT Open Silicon

Bringing HUFLIT into the open-source silicon value chain, starting at the layer
where low-cost, high-quality intellectual labor has a real edge: **AI-assisted
verification on open-source IP** — Verilog/RTL, cocotb/Verilator testbenches,
and open PDK tape-out flows (LibreLane), all delivered fully in digital form.

This is a 24-month program, not a lab or a degree program. Phase 0 (first 90
days) is a single-person validation: find and test one person capable of
getting a real pull request merged into an international open-source project.
No organization, no procurement, no announcement before that gate is cleared.

Full context, positioning, roadmap with stage gates, and ADRs:
[`docs/OPEN_SILICON_KICKOFF.md`](docs/OPEN_SILICON_KICKOFF.md).
Evolving source of truth for decisions: [`PROJECT_INSTRUCTIONS.md`](PROJECT_INSTRUCTIONS.md).

## Repository layout

```
docs/            Kickoff doc, runbook, ADRs (docs/decisions/), Vietnamese
                 translations (docs/vi/) contributed back upstream
designs/         Small learning designs (e.g. a first counter/UART), RTL→GDSII
                 practice — not for tape-out (see ADR-OS-003)
verification/    cocotb testbenches — the primary product of this program
docker/          Reproducible tool environment (IIC-OSIC-TOOLS-based)
.github/         CI: lint -> simulate -> LibreLane -> hash comparison
wiki/            Agent memory for this repo (not for humans)
```

## Getting started (Phase 0, weeks 1-2)

```
docker compose -f docker/docker-compose.yml run --rm librelane-dev
librelane --smoke-test
```

See [`docs/RUNBOOK.md`](docs/RUNBOOK.md) for the full setup and regression
workflow.

## Principles

- Public repository, English-first, from day one (ADR-OS-004) — Vietnamese
  translations live in `docs/vi/` as a HUFLIT-owned asset contributed upstream.
- Every decision with a tradeoff gets an ADR in `docs/decisions/`.
- No secrets in Git. No proprietary tooling required to reproduce any result
  in this repo.

## License

[Apache License 2.0](LICENSE) — matches the license used by LibreLane and
most of this ecosystem.
