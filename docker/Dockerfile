# Reproducible tool environment for Vega (HUFLIT Open Silicon).
#
# Built on IIC-OSIC-TOOLS (JKU Linz) — bundles Yosys, OpenROAD, Magic,
# KLayout, ngspice, LibreLane, Verilator, cocotb. See docs/OPEN_SILICON_KICKOFF.md
# section 2.1 and 5.1.
#
# Pinned to the 2026.08 monthly release (2026-08-25) for reproducibility --
# was ":latest" (a floating tag) until 2026-09-16. Confirmed on Docker Hub
# to be ~3.76GB compressed (vs. an unpinned multi-version-accreted
# ":latest" pull observed locally at ~16GB uncompressed on disk). Bump
# deliberately (not automatically) when there's a reason to, and note the
# change in backlog.md -- see https://github.com/iic-jku/IIC-OSIC-TOOLS for
# the tag list.
FROM hpretl/iic-osic-tools:2026.08

WORKDIR /workspace
