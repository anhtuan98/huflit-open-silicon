---
sources: [docker/Dockerfile, docker/docker-compose.yml, designs/counter3/verify/Makefile]
related: [[librelane-config-for-tiny-designs]]
created: 2026-09-14
updated: 2026-09-14
---

# Docker Toolchain Invocation (IIC-OSIC-TOOLS)

## Entry Points
- `docker/docker-compose.yml` -- service `librelane-dev`, builds from
  `docker/Dockerfile` (`FROM hpretl/iic-osic-tools:latest`), mounts repo
  root at `/workspace`.
- Standard invocation:
  `docker compose -f docker/docker-compose.yml run --rm librelane-dev --skip <command...>`

## Key Patterns
- The image's entrypoint is **not a plain shell** -- it's a script that by
  default tries to start a VNC/X11 UI. `--skip` (or `-s`) must be the
  **first** argument after the image/service name to bypass the UI and run
  a command directly. Without it, the container just prints usage and
  exits 0 (looks like success in a script, isn't).
- To run a command in a subdirectory of the repo (e.g. a specific
  `designs/<name>/`), override the working dir on the `run` invocation
  rather than `cd`-ing inside a wrapped `bash -c`:
  `docker compose -f docker/docker-compose.yml run --rm --workdir /workspace/designs/counter3 librelane-dev --skip librelane config.yaml`
- `librelane --smoke-test` intentionally discards its run directory on exit
  (by design, not a bug) -- it's a toolchain sanity check, not a way to get
  a persisted artifact. For a persisted GDSII from a bundled example, use
  `librelane --run-example <name>` with `--workdir` pointed at a directory
  under `/workspace` so the output lands on the host, not just inside the
  ephemeral container filesystem.
- cocotb testbenches use the classic Makefile flow:
  `include $(shell cocotb-config --makefiles)/Makefile.sim` still works on
  cocotb 2.0.1 (bundled in this image) despite cocotb 2.0's newer
  `cocotb.runner` Python API existing as an alternative.
- Container's ambient `$PDK` defaults to `ihp-sg13g2` -- see
  [[librelane-config-for-tiny-designs]] for why this matters and how to
  override it.

## Search Shortcuts
- Grep: `--skip`, `--workdir`, `cocotb-config --makefiles`
- Dir: `docker/`, `designs/*/verify/Makefile`

## Gotchas
- `librelane --version` / `--help` / `--smoke-test` all need the `--skip`
  prefix too, not just full flow runs -- forgetting it just prints usage,
  which can look like a no-op success (exit code 0) in a script that pipes
  through `tail` or similar.
