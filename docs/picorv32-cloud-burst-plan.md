# picorv32 Cloud Compute Burst — Plan

| | |
|---|---|
| **Program** | HUFLIT Open Silicon (codename Vega) |
| **Trigger** | Thầy renting a Linode Dedicated CPU VM (32 vCPU, 96GB RAM) for a 2-3 hour test, 2026-09-16 |
| **Status** | **DRAFT — local de-risking in progress, not yet approved to rent** |
| **Owner** | thầy approves the actual rental; setup below is prepared in advance so the metered window is spent computing, not configuring |

## 1. What this is and why it's worth the money

Thầy asked for something "heavy but meaningful" for the program's 12-month
roadmap, not just a stress test. Two things happen in the same 2-3 hour
window, on the same rented hardware:

1. **A third learning design, one real tier up from `counter3` and
   `uart`.** `designs/picorv32/` — YosysHQ's `picorv32` RISC-V core
   (~2,140 lines, ISC license, single file, one of the best-known small
   open cores in the ecosystem) taken through the full LibreLane
   RTL-to-GDSII flow. This is thousands of standard cells, not `uart`'s
   ~290 — genuinely too slow to iterate on comfortably on a laptop, which
   is exactly the shape of workload a burst rental is *for*. If it signs
   off clean, it becomes the third entry in the `counter3` ->
   `uart` -> `picorv32` teaching series (same technical-report/slide
   treatment as the other two, written up afterward).
2. **The "poor man's ECC" determinism check the kickoff doc already
   names as valuable** (`docs/OPEN_SILICON_KICKOFF.md` §5.2): run the
   same flow multiple times independently and diff the output GDS
   hashes. A mismatch means something is wrong -- in the tool, the
   config, or the environment -- and this also catches *software* bugs,
   not just hardware bit-flips. It's explicitly called out as suitable
   for a weekly CI job once there's a regression server; this burst is
   the first time it actually runs, for real, instead of staying a
   paragraph in a planning doc. It is also **embarrassingly parallel**
   ("mỗi test là một tiến trình đơn luồng" -- kickoff doc's own words),
   which is exactly what a 32-core rental is good at and a laptop is not.

A third thing falls out for free: **real measured data** (wall-clock time
per flow phase, peak RAM) to check against kickoff doc §5.2's own
un-measured guess for a future regression server ("128-256GB RAM... nút
thắt thật"). Whatever this run shows -- comfortable, tight, or
insufficient at 96GB for a design this size -- is a citable data point
for that future purchasing decision, not another guess.

**What this is not:** not a tape-out attempt (ADR-OS-003 still applies --
GDSII stays local evidence, nothing gets submitted anywhere), not a
commitment to adopt `picorv32` as an ongoing project design, and not the
Gate 0 deliverable itself (`obi_uart` / `apb_timer` remain the actual PR
targets -- see `backlog.md`). It is infrastructure validation plus a
teaching asset, paid for once, in cash the program's own budget already
allocates to compute (ADR-OS-006: ~20% compute).

## 2. Why the config is being debugged locally FIRST, for free

Every prior design (`counter3`, `uart`) needed 2-4 debug iterations
against real LibreLane errors before reaching clean signoff (`PDN-0185`,
`DPL-0036`, a post-route max-slew violation -- see the wiki articles
under `wiki/`). There is no reason to expect `picorv32` -- much bigger --
to be exempt from needing at least one round of that. **Every minute of
that debugging must happen before the metered clock starts**, on this
local machine (8 cores / ~23GB RAM here, slower than the target VM but
free). A background agent is doing exactly this right now: regression-
checking the newly pinned toolchain image against `counter3`/`uart` first
(a version bump must not be the thing that breaks the burst), then
authoring and iterating on `designs/picorv32/` until it's either clean or
provably close, and measuring real resource usage along the way.

**This plan is not final until that comes back.** The sections below
describe the mechanism and are ready to run; the specific numbers
(replica count, time budget split) get filled in from real local
measurements, not guessed.

## 3. Toolchain: the floating-tag TODO got resolved along the way

`docker/Dockerfile` now pins `hpretl/iic-osic-tools:2026.08` instead of
the long-floating `:latest` (a TODO open since the repo's first week --
see `backlog.md`). Checked directly against Docker Hub: `2026.08` is
~3.76GB compressed, vs. the `:latest`-based image observed locally at
~16GB *uncompressed on disk* (most of that is accreted layers across
versions, not what actually transfers over the network) -- either way,
pinning gives a VM boot a predictable, reproducible pull instead of an
unbounded floating one. This also means the burst run's result is
reproducible by anyone re-running `docker compose build` from this repo
at any point in the future, not just "whatever `:latest` happened to be
on 2026-09-16."

## 4. Mechanism

Three phases, all scripted (`docker/cloud-burst/`), so the live window is
"run the script and watch," not "figure out what to type next" -- see §2
of this doc for why that discipline matters here specifically.

1. **Bootstrap** (`bootstrap.sh`, run once over SSH right after the VM
   boots): installs Docker, clones the repo at a specific branch (pushed
   in advance -- see §5), pulls/builds the pinned image. Fully
   unattended, no interactive steps.
2. **Drive** (`driver.sh`, run inside `tmux` so it survives an SSH
   disconnect): Phase A runs one reference `picorv32` flow, timed. Phase
   B computes, from that *measured* time plus remaining budget plus RAM
   ceiling, how many parallel replica runs of the identical config can
   realistically finish, and launches exactly that many for the
   determinism check. Phase C hits a hard cutoff with a safety margin
   before the budget runs out, stops waiting on stragglers, and bundles
   whatever `final/` artifacts exist.
3. **Retrieve** (`retrieve.sh`, run from the laptop): pulls down one
   small curated tarball -- final GDSII + `metrics.json` + `flow.log` per
   completed run, explicitly *not* the bulky per-stage intermediate
   directories -- plus a `summary.md` with a pass/fail verdict on the
   hash comparison and a metrics table. This is the step that has to be
   fast, and is, because the bundle was curated on the VM before transfer
   started, not after.

The guaranteed floor outcome, even in the worst case (Phase A alone eats
the whole budget): one real, meaningfully-sized open design signed off
end to end on rented hardware, with real timing/RAM data. The determinism
check is the stretch goal on top, sized to whatever time is actually left
over -- not assumed in advance.

## 5. Live checklist (for whoever is at the keyboard when the VM exists)

- [ ] Confirm the background de-risking agent's report: pinned-image
  regression clean on `counter3`/`uart`, and `picorv32` reached at least
  a known, understood state locally (ideally clean signoff; at minimum,
  past floorplan/PDN generation without error).
- [ ] Review `designs/picorv32/` (RTL provenance/license, config, test)
  and the `docker/cloud-burst/` scripts -- this doc will be updated once
  that review is done; nothing here has been pushed or run for real yet.
- [ ] Commit the reviewed `designs/picorv32/` + `docker/cloud-burst/` +
  `docker/Dockerfile` pin to a branch (not `main` directly -- e.g.
  `picorv32-cloud-burst`) and push it. `bootstrap.sh` clones from GitHub;
  it does not copy uncommitted local files.
- [ ] Confirm the exact hourly rate in the Linode Cloud Manager before
  confirming the rental -- **this plan could not get a precise live
  price via automated fetch** (Akamai/Linode's pricing pages are
  JS-rendered; only one data point surfaced, an entry-level Dedicated
  CPU rate of ~$0.0648/hr, which is not the 32-core/96GB plan). Budget
  for a 3-hour window at whatever the Cloud Manager quotes for the
  32 vCPU / 96GB Dedicated CPU plan before confirming.
- [ ] Rent the VM (Ubuntu, region close to thầy, Dedicated CPU 32/96GB).
- [ ] SSH in, run `bootstrap.sh <branch-name>`.
- [ ] `tmux new -s burst`, then run `driver.sh` with `PEAK_RAM_GB` set
  from the local de-risking measurement.
- [ ] Detach (`Ctrl-b d`), periodically reattach (`tmux attach -t burst`)
  to check progress -- no need to stay connected continuously.
- [ ] Once `driver.sh` prints `[OK] Done` and shows the summary: run
  `retrieve.sh <vm-ip>` from the laptop.
- [ ] Verify the retrieved bundle (`cat summary.md`, spot-check a GDS
  file opens) *before* destroying the VM -- a bad transfer discovered
  after the VM is gone is data lost for the cost of nothing gained.
- [ ] Destroy the Linode VM.
- [ ] Fold results into `backlog.md`, and if `picorv32` signed off clean,
  write the third teaching report/slide pair (`docs/picorv32-technical-report.md`
  etc., same structure as `counter3`/`uart`'s).

## 6. Open items / not yet resolved

- Exact rental cost per hour (see checklist item above -- confirm live
  in Cloud Manager, don't rent on a guessed number).
- Replica count `N` for the determinism check -- computed by `driver.sh`
  itself from real Phase A timing, not fixed in advance.
- Whether `designs/cloud-burst/` scripts need reconciling with an
  alternate version the local de-risking agent may also produce (both
  are exploring the same mechanism in parallel by design -- whichever
  is better-evidenced by the time real numbers come back gets kept, not
  both).

## Changelog

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-09-16 | First draft, written while local de-risking is still in progress. Not yet approved to execute. |
