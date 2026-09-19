# picorv32 — Fine-Tuning a Real RISC-V Core Through an Open-Source ASIC Flow: A Debugging Journal

| | |
|---|---|
| **Program** | HUFLIT Open Silicon (codename Vega) |
| **Design under study** | [`designs/picorv32/`](../designs/picorv32/) |
| **Context** | Local de-risking ahead of a planned cloud compute burst (ADR-OS-007), and the program's third learning design after `counter3` and `uart_top` |
| **Dates** | 2026-09-16 (local exploration) – 2026-09-17 (cloud-run preparation) |
| **Status** | Timing-clean local result achieved; max-slew/max-cap violations and the full cloud run remain open |
| **Audience** | Teaching material and, candidly, a test of whether this work is worth publishing at all (see §1) |

## Abstract

This report is not a success story with the difficult parts edited out.
It is a chronological account of trying to take a real, well-known
open-source RISC-V core — `picorv32`, from YosysHQ — through a complete
LibreLane RTL-to-GDSII flow, written down attempt by attempt, including
five failed or unsatisfactory runs before a clean one, three independently
confirmed out-of-memory kills, and one anomaly this report does not claim
to fully explain. The purpose of documenting it this way is explicit: the
value here was never going to be "we ran picorv32" — picorv32 has been run
through this class of flow more times than anyone has counted. The value
is in three specific, reusable findings about how LibreLane itself behaves
at a scale larger than this program's first two designs (`counter3`,
`uart_top`) ever exercised, and in an honest record of how each finding
was actually reached — including the wrong turns — because that record is
the part a student or the next engineer can actually learn from. Section 1
addresses directly whether this exercise is worth publishing at all, since
that question was asked before this report was written, not after.

## 1. Is This Worth Publishing?

This question was asked deliberately, before writing this report, not as
a rhetorical framing device afterward. The honest answer has two parts.

**As a contribution to `picorv32` itself: no.** No RTL bug was found. No
pull request will be filed against YosysHQ's repository. `picorv32` is
one of the most-synthesized open-source cores in existence; running it
through a LibreLane flow again does not advance the state of that project
in any way. If the bar for "worth doing" were "does this produce a merged
PR," this exercise fails that bar, and should be labeled honestly as such
rather than dressed up as more than it is.

**As a public technical article: yes, on a narrower and more honest
basis.** Three findings in this report (§6) are not specific to
`picorv32` — they are facts about LibreLane's own behavior at a design
scale (~19,000 instances) this program had not previously exercised, and
at least one of them (the threading auto-detection gap, §6.1) looks like
a genuine discrepancy between LibreLane's documentation and its actual
behavior in this toolchain image, worth reporting upstream independently
of any article. A reader trying to run a similarly-sized design through
this same open-source flow would plausibly hit the same three walls this
report hit, and would plausibly save real time — and, if renting cloud
compute, real money — by reading this first. That is a legitimate,
if modest, basis for publication: not "look what we built," but "here is
what broke, and here is the receipt."

The reader should weigh this report accordingly: it is closer to a lab
notebook than a product announcement, and that is the intended register.

## 2. Why picorv32, and Why Now

The program's roadmap (`docs/OPEN_SILICON_KICKOFF.md` §4) calls for one
self-written design through full sign-off (satisfied by `counter3`) and
optionally a second, larger one to exercise more of the flow (`uart_top`,
~290 cells). Both are complete and documented
(`docs/counter3-technical-report.md`, `docs/uart-technical-report.md`).

Separately, `docs/decisions/ADR-OS-007-rent-compute-before-buying.md`
committed this program to renting cloud compute by the hour rather than
buying dedicated hardware, for cost reasons during a personnel-risk-heavy
early phase. Before spending real money on a rented VM, the natural
question was: rent it to do *what*, specifically? A design an order of
magnitude larger than `uart_top` was chosen for three reasons:

1. **It would actually stress CPU/RAM in ways `uart_top` did not**,
   making it possible to validate — rather than guess — the RAM sizing
   question `docs/OPEN_SILICON_KICKOFF.md` §5.2 had left as an unverified
   estimate ("128-256GB, RAM is the real bottleneck").
2. **A design this size is realistically only iterable on a laptop with
   difficulty** (as this report demonstrates: a single attempt took over
   an hour before a config fix), which is exactly the shape of problem
   renting burst compute is meant to solve — but only if the config is
   *already correct* before the metered clock starts. That meant doing
   the hard debugging locally first, for free, however long it took.
3. **`picorv32` specifically** was chosen over an arbitrary large block
   because it is a single Verilog file (~3,050 lines including several
   unused wrapper variants), ISC-licensed (fully permissive), requires no
   external toolchain beyond what this repository's Docker image already
   provides, and is well-understood enough that if something broke, the
   cause was overwhelmingly likely to be in the flow or its
   configuration, not in unfamiliar or buggy RTL.

## 3. The Design

[`designs/picorv32/src/picorv32.v`](../designs/picorv32/src/picorv32.v),
fetched verbatim from
`https://raw.githubusercontent.com/YosysHQ/picorv32/master/picorv32.v`.
The file defines several modules (`picorv32`, `picorv32_axi`,
`picorv32_wb`, PCPI multiply/divide co-processors, a register-file
variant); only the plain `picorv32` core module is targeted as the
synthesis top — Yosys elaborates only what is reachable from the
specified top module, so the unused wrapper modules in the same file are
simply ignored.

The core's top-level interface (defaults used, no parameter overrides):

```verilog
module picorv32 #(
    parameter [ 0:0] ENABLE_COUNTERS = 1,
    parameter [ 0:0] ENABLE_REGS_16_31 = 1,
    parameter [ 0:0] ENABLE_REGS_DUALPORT = 1,
    parameter [ 0:0] TWO_STAGE_SHIFT = 1,
    parameter [ 0:0] BARREL_SHIFTER = 0,
    parameter [ 0:0] CATCH_MISALIGN = 1,
    parameter [ 0:0] CATCH_ILLINSN = 1,
    parameter [ 0:0] ENABLE_PCPI = 0,
    parameter [ 0:0] ENABLE_MUL = 0,
    parameter [ 0:0] ENABLE_DIV = 0,
    parameter [ 0:0] ENABLE_IRQ = 0,
    ...
) (
    input clk, resetn,
    output reg trap,
    output reg mem_valid, mem_instr,
    input mem_ready,
    output reg [31:0] mem_addr, mem_wdata,
    output reg [3:0] mem_wstrb,
    input [31:0] mem_rdata,
    ...
);
```

At default parameters, multiply/divide/PCPI/IRQ are disabled but the
dual-port register file, counters, and misaligned/illegal-instruction
trapping are enabled — a moderately full-featured, memory-mapped RV32I
core with no cache and no bus protocol of its own (the `mem_*` signals
are a simple valid/ready handshake the surrounding SoC is expected to
serve). No cocotb testbench was written for this design in this
exercise — functional (ISA-level) verification of `picorv32` was
explicitly out of scope; the object under study here is the *physical
implementation flow*, not the core's correctness (which YosysHQ and a
large existing user base have already exercised far more thoroughly than
this program could in one sitting).

## 4. Hardware Used

Precision here matters for anyone trying to reproduce or compare against
these numbers.

| | |
|---|---|
| **Local machine** | 11th Gen Intel Core i7-11370H @ 3.30GHz — **4 physical cores, 8 logical (hyperthreaded)**, `nproc` reports 8; ~23GB RAM |
| **Toolchain image** | `hpretl/iic-osic-tools:2026.08` (pinned; see `docker/Dockerfile`), LibreLane v3.1.0.dev3, sky130A / `sky130_fd_sc_hd` |
| **Later reference point (§9)** | The Linode VM this work was preparing for reports its underlying physical CPU as an AMD EPYC 7601 (32-core, Zen 1, 2.2GHz base clock) under KVM virtualization |

The distinction between 4 physical and 8 logical cores on the local
machine is not pedantic: it directly explains why the threading fix in
§6.1 produced roughly a 3x wall-time improvement rather than something
closer to 8x — hyperthreading gives real but sub-linear returns on
CPU-bound compilation/PnR work, and a report that said "8 cores" without
qualification would over-promise what the same fix should be expected to
do on a genuinely 8-physical-core machine.

## 5. The Attempts, in Order

Every attempt below ran the same command shape:

```bash
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/picorv32 \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd config.yaml
```

with `designs/picorv32/config.yaml` edited between attempts as described.
`runs/` was deleted before each attempt to avoid confusion between
results (a decision revisited critically in §5.5).

### 5.1 Attempt 1 — baseline, and an unnoticed bug

```yaml
DESIGN_NAME: picorv32
VERILOG_FILES: dir::src/*.v
CLOCK_PERIOD: 10
CLOCK_PORT: clk
```

Nothing about threading was configured — the assumption, unexamined at
the time, was that LibreLane would use the available cores by default.

**Result: hard failure after 61 minutes 39 seconds** (08:36:36 –
09:38:15 UTC). Synthesis, floorplanning, placement, CTS, and routing all
completed without error; the flow terminated only at final signoff:

```
[ERROR] The following error was encountered while running the flow:
        One or more deferred errors were encountered:
        Setup violations found in the following corners:
        * max_ss_100C_1v60
        * min_ss_100C_1v60
        * nom_ss_100C_1v60
[ERROR] LibreLane will now quit.
```

This is an unsurprising result on its own — a real CPU core targeted at
100MHz (10ns) on sky130 with no timing-strategy tuning failing to close
at the slowest process/voltage/temperature corner is a plausible, almost
expected outcome. What made this attempt worth a closer look was a
side observation while it ran: a periodic resource logger (`docker
stats` + `free -h`, sampled every 20 seconds for the full 358-sample
duration) never once recorded CPU usage above **~101%** — on an
8-logical-core machine. Peak container memory across the entire run was
a modest ~763MiB.

Grepping the flow log for the word "thread" surfaced the actual cause:

```
[VERBOSE] OpenROAD will use None threads
[WARNING] [ORD-0032] Invalid thread number specification: None
```

**This is Finding #1 (§6.1) — but at this point in the narrative it was
just an anomaly, not yet a documented finding.** The immediate
implication was narrower: this hour-long run had used the equivalent of
one core the entire time, on a machine with eight logical cores sitting
idle. Before drawing conclusions about `picorv32`'s timing, the
threading configuration needed fixing first — an unrelated bug was
confounding the actual experiment.

### 5.2 Attempt 2 — fix threading, relax the clock

Two changes at once (in hindsight, changing two variables in one step
was a minor methodological shortcut — see the retrospective note in
§5.5):

```yaml
CLOCK_PERIOD: 25          # relaxed from 10ns
OPENROAD_THREADS: 8
STA_THREADS: 9            # one per PVT corner
```

**Result: hard failure again, same three corners, but in 21 minutes 6
seconds** (09:39:56 – 10:01:02 UTC) — roughly a **3x wall-time
improvement**, consistent with §4's hyperthreading caveat. This alone
confirmed the threading fix was real and effective, independent of
whether the timing problem was solved. Checking `final/metrics.json`
(written despite the nonzero exit — see the note in §5.5) for the first
time in this exercise:

| Metric | Value |
|---|---|
| Design instance count | 19,208 |
| Worst-case setup slack | −2.483 ns |
| Setup violation count | 9 |
| Setup TNS (total negative slack) | −4.889 ns |

Relaxing the clock by 2.5x (10ns → 25ns) had *not* proportionally fixed
the violations — a hint, not yet understood at this point, that the
default synthesis approach itself, not just the clock target, was part
of the problem.

### 5.3 Attempt 3 — relax further; first "success" that wasn't clean

```yaml
CLOCK_PERIOD: 30
```

(threading unchanged). This run also became the occasion for an
unrelated infrastructure problem: the shell-level process monitoring
this run's background execution was killed twice by this development
machine's own memory-pressure guard, unrelated to the container's actual
memory use (confirmed by checking — the container itself was healthy,
using ~1.4GB, mid-routing, with a falling violation count). The run was
re-attached via `docker wait` on the existing container ID rather than
restarted, and eventually completed.

**Result: exit code 0** ("Flow complete") — the first attempt to finish
without a hard error. But `flow__errors__count == 0` did not mean clean:

| Metric | Value |
|---|---|
| Design instance count | 19,208 |
| Worst-case setup slack | **−3.093 ns (still violated)** |
| Setup violation count | 11 |
| Max-slew violations | 4,682 |
| Max-cap violations | 20 |
| Total power | 7.26 mW |

This is the first appearance of an anomaly this report does not claim to
fully explain: attempts 1 and 2, with *less negative* worst-case slack
(−2.48ns) than this attempt (−3.09ns), triggered LibreLane's hard
"Setup violations found... will now quit" path, while this attempt, with
*worse* slack, did not. Whatever criterion actually triggers that hard
stop, it is evidently not simply "does a setup violation exist" or "how
negative is the worst slack" — some other threshold (plausibly on TNS,
or the specific PVT corner set, or something else not investigated
here) governs it. This report flags this explicitly as an **open
question** rather than asserting an unverified explanation for it.

DRC, LVS, and antenna were clean at this point, which is itself a datum
worth stating plainly: a design can be physically legal and
signoff-passable on every axis except timing, and LibreLane's own exit
code does not reliably distinguish "clean" from "has thousands of
uncorrected slew/cap violations."

### 5.4 Attempt 4 — the synthesis strategy was the missing variable

At this point (per thầy's explicit instruction to continue exploring
"for richer context and different fine-tuning test cases"), the
configuration space search became deliberate rather than reactive.
Querying LibreLane's own step definitions directly, rather than guessing
from documentation:

```bash
docker compose -f docker/docker-compose.yml run --rm librelane-dev --skip \
  python3 -c "
from librelane.steps import Yosys
for v in Yosys.Synthesis.config_vars:
    if 'STRATEGY' in v.name:
        print(v.name, '| default=', v.default, '|', v.description[:200])
"
```

```
SYNTH_STRATEGY | default= AREA 0 | Strategies for abc logic synthesis
and technology mapping. AREA strategies usually result in a more
compact design, while DELAY strategies usually result in a design that
runs at a higher frequency.
```

The default is optimized for area, not delay — a reasonable default for
a general-purpose flow, but a poor fit for a design already failing
timing. Changed to the most aggressive delay-oriented option:

```yaml
CLOCK_PERIOD: 25           # tightened back from 30
SYNTH_STRATEGY: "DELAY 4"
```

**Result:** exit 0, and a real improvement *despite a tighter clock than
attempt 3's*:

| Metric | Attempt 3 (`AREA 0`, 30ns) | Attempt 4 (`DELAY 4`, 25ns) |
|---|---|---|
| Worst-case setup slack | −3.093 ns | **−2.157 ns** |
| Setup violations | 11 | 3 |
| Max-slew violations | 4,682 | 2,862 |
| Max-cap violations | 20 | 31 |
| Design instance count | 19,208 | 19,062 |
| Total power | 7.26 mW | 6.67 mW |

A better result at a *tighter* timing target than the previous attempt's
*looser* one is the clearest possible signal that the synthesis strategy,
not just the clock period, was the dominant lever — this is **Finding
#2** (§6.2).

### 5.5 Attempt 5 — clean timing, finally

Combining the tighter clock relaxation with the working strategy:

```yaml
CLOCK_PERIOD: 30
SYNTH_STRATEGY: "DELAY 4"
```

**Result: setup and hold timing fully clean.**

| Metric | Value |
|---|---|
| Worst-case setup slack | **+2.790 ns (met)** |
| Setup violations | **0** |
| Worst-case hold slack | +0.115 ns (met) |
| Hold violations | 0 |
| Magic DRC / KLayout DRC / LVS / antenna | all clean |
| Max-slew violations | 2,837 (unchanged in kind from attempt 4) |
| Max-cap violations | 31 |
| Total power | 5.56 mW |
| Design instance count | 19,058 |

This is the first genuinely good result in this exercise: real setup and
hold timing closure on a ~19,000-instance RISC-V core, on a laptop, with
DRC/LVS/antenna all clean. It is not a *complete* signoff — thousands of
max-slew/max-cap violations remain — but it is the point at which the
exercise stopped being "make it fail less" and became "fix the specific
remaining problem."

**A process mistake to disclose rather than hide:** this run's `runs/`
directory was deleted before starting attempt 6 (following the pattern
used in every prior attempt), which meant the actual GDSII and full logs
from this clean result were **not preserved** — only the metrics printed
to the terminal during the session survived. This was only noticed
several attempts later (§5.8) and had to be corrected by re-running this
exact configuration a second time. The lesson is stated plainly in §6.4
rather than glossed over: **deleting a run directory before confirming
its artifacts are no longer needed is a real, avoidable mistake**, not a
hypothetical one — it happened, in this exercise, to what was at the
time the best result obtained.

### 5.6 Attempt 6 — chasing the residual violations, too aggressively

`designs/uart/`'s own signoff report
(`docs/uart-technical-report.md` §4.2) had previously fixed a similar
(much smaller-scale) residual slew-violation problem via
`DESIGN_REPAIR_MAX_SLEW_PCT`/`GRT_DESIGN_REPAIR_MAX_SLEW_PCT`. Querying
LibreLane's config variables the same way as in §5.4 surfaced the full
family:

```
DESIGN_REPAIR_MAX_SLEW_PCT | default= 20
DESIGN_REPAIR_MAX_CAP_PCT | default= 20
GRT_DESIGN_REPAIR_MAX_SLEW_PCT | default= 10
GRT_DESIGN_REPAIR_MAX_CAP_PCT | default= 10
```

Given the much larger violation count here than `uart` ever had (2,837
vs. 4), the margins were widened aggressively rather than incrementally:

```yaml
DESIGN_REPAIR_MAX_SLEW_PCT: 40
DESIGN_REPAIR_MAX_CAP_PCT: 40
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 30
GRT_DESIGN_REPAIR_MAX_CAP_PCT: 30
```

**Result: a hard crash, not a graceful failure.**

```
[ERROR] The flow has encountered an unexpected error:
        OpenROAD.RepairDesignPostGPL failed with an unexpected error.
        Please check '.../32-openroad-repairdesignpostgpl/...' and
        unless you wrote the step yourself, file an issue.
```

The step's own log showed the repair pass beginning normally — "Iteration
0 | +0.0% | 0 | 0 | 0 | 6316" (6,316 nets identified for repair) — and
then nothing further. No stack trace, no explicit error text, just
silence where the next iteration's line should have been. At this point
in the narrative, the cause was unknown; LibreLane's own suggested next
step ("file an issue") assumes a tool bug, which turned out to be a
plausible but incorrect first guess.

### 5.7 Attempt 7 — same crash at a more conservative margin

To isolate whether 40% specifically was the problem, the margins were
brought back to exactly `uart`'s own working values:

```yaml
DESIGN_REPAIR_MAX_SLEW_PCT: 25
GRT_DESIGN_REPAIR_MAX_SLEW_PCT: 15
# cap margins left at default (20 / 10)
```

**Result: the identical crash**, at the identical point ("Iteration 0 |
... | 6316" then nothing), a mere margin change away from the previous
attempt. This is the first strong evidence that the *value* of the
margin was not the variable that mattered — something about invoking
this repair pass **at all**, on a design this size, was the problem.

At this point the investigation moved from LibreLane's own log (which
had nothing more to offer) to the host kernel's log:

```bash
journalctl -k | grep -i "out of memory: killed process.*openroad"
```

```
Out of memory: Killed process 154090 (openroad)
  total-vm:26842284kB anon-rss:20885252kB
```

**The process had grown to ~19.9GB of resident memory before the kernel
killed it.** This reframes both crashes entirely: not a LibreLane bug,
not a bad margin value, but a genuine memory requirement — for this
specific repair operation, on this specific design — that exceeded what
this 23GB laptop could sustain once its own overhead (OS, this very
Claude Code session, everything else running) was accounted for.

### 5.8 Attempt 8 — ruling out threading as the memory driver

One remaining hypothesis: perhaps `OPENROAD_THREADS: 8` was itself
multiplying memory use (e.g., duplicated working state per thread), and
a smaller thread count would fit in available memory.

```yaml
OPENROAD_THREADS: 4
STA_THREADS: 4
# slew/cap margins unchanged from attempt 7 (25 / default / 15 / default)
```

**Result: the identical crash, at the identical point, with 4 threads
instead of 8.** Checking the kernel log again:

```
Out of memory: Killed process 154850 (openroad)
  total-vm:26199672kB anon-rss:20772264kB
```

**~19.8GB resident — essentially identical to attempt 7's ~19.9GB,
despite half the thread count.** This is conclusive: the memory
requirement belongs to the repair algorithm's handling of this many
nets (6,316) on this design, not to `OPENROAD_THREADS`. A third
independent confirmation of the same failure signature, with two
different thread counts producing near-identical memory footprints,
is stronger evidence than any single crash could have been — this is
**Finding #3** (§6.3), and the reason this report can state it as a
finding rather than a guess.

At this point, three consecutive attempts (6, 7, 8) had failed the same
way for a now-understood reason. Continuing to vary the margin value
further, locally, would not have produced a different outcome — the
constraint was memory, and this machine's memory was fixed. This is
exactly the kind of wall a cloud burst with substantially more RAM is
meant to be used against, and the exercise stopped here rather than
continuing to spend time restating the same result a fourth time.

### 5.9 Attempt 9 — regenerating the lost clean result

To correct the §5.5 mistake, attempt 5's exact configuration (no slew/cap
margin overrides, `OPENROAD_THREADS: 8` / `STA_THREADS: 9` restored) was
re-run specifically to preserve its artifacts this time.

**Result: metrics identical to attempt 5 to the number of significant
figures reported** — worst-case setup slack +2.790ns, 0 setup/hold
violations, 2,837 max-slew / 31 max-cap violations, 19,058 instances.
This was not the primary goal of the re-run, but it is worth stating as
a small, informal confirmation of **determinism**: the same config, run
a second time (on the same machine, same toolchain image), produced a
bit-for-bit-consistent metrics report. This is the same property
`docs/OPEN_SILICON_KICKOFF.md` §5.2 names as worth checking systematically
("run the same design twice, diff the GDS hash") — this exercise did not
diff the actual GDS hash, only the summary metrics, so it should be read
as suggestive, not as the systematic check itself (which remains a
planned part of the eventual cloud run, §9).

This run's artifacts were preserved: `designs/picorv32/runs/` (gitignored,
regenerate via the command in §8), including a 15,096,966-byte
(~14.4MB) `picorv32.gds`, across all 76 flow stages.

## 6. The Three Findings, Consolidated

The attempt-by-attempt narrative in §5 shows *how* each of these was
found; this section states each one directly, for a reader who wants the
conclusion without the story.

### 6.1 `OPENROAD_THREADS`/`STA_THREADS` silently default to 1 thread

Both variables default to `None`, documented as resolving to "the
machine's core count" when unset. Observed behavior in this
IIC-OSIC-TOOLS-based container (`hpretl/iic-osic-tools:2026.08`, LibreLane
v3.1.0.dev3): unset means **one thread**, confirmed by the log's own
`OpenROAD will use None threads` / `[ORD-0032] Invalid thread number
specification: None` warning, and independently by `docker stats` never
exceeding ~101% CPU across a full one-hour run on an 8-logical-core
machine.

**Fix:** set explicitly, e.g. `OPENROAD_THREADS: 8`, `STA_THREADS: 9`
(one per PVT corner is a reasonable default — this toolchain checks 9).
Measured effect on this design: **wall time for an otherwise-identical
full flow dropped from 61m39s to 21m6s** (§5.1 vs. §5.2), a ~3x
improvement consistent with 4 physical cores under hyperthreading.

**This looks like a genuine documentation-vs-behavior gap in LibreLane,
not solely a configuration mistake on this program's part**, and is
worth reporting to the `librelane/librelane` project independently of
this report — a small, low-risk community contribution distinct from
(and easier than) the Gate 0 work this program is separately pursuing on
`obi_uart`/`apb_timer`.

**Practical rule going forward:** never trust "auto-detects core count"
documentation for this toolchain without checking `docker stats` (or
equivalent) during at least one run. Set thread counts explicitly, every
time, on every new machine size — which is exactly why §9's portable
`-c OPENROAD_THREADS=$(nproc)` approach exists.

### 6.2 `SYNTH_STRATEGY` defaults to area-optimized, not timing-optimized

Default `"AREA 0"`. For a design already failing timing, `"DELAY 4"`
(the most aggressive delay-oriented ABC strategy LibreLane offers)
produced a better timing result at a *tighter* clock target than the
default strategy achieved at a *looser* one (§5.3 vs. §5.4: −3.09ns
worst slack at 30ns under `AREA 0`, vs. −2.16ns at 25ns under `DELAY 4`).
Combined with the clock relaxation that had already been planned
anyway, `DELAY 4` was the difference between a design that never closed
timing (attempts 1–4) and one that did (attempt 5).

**Practical rule:** for any design large enough to have genuine timing
risk (a real datapath, not `counter3`- or `uart_top`-scale), try a
`DELAY` strategy before — or at least alongside — relaxing the clock
target. Relaxing the clock alone, as attempts 1→2→3 did, is treating the
symptom; changing the strategy, as attempt 4 did, addressed something
closer to the cause.

### 6.3 Explicit slew/cap repair margins can OOM-kill OpenROAD at this design's scale

`designs/uart/`'s own fix for a residual max-slew violation
(`DESIGN_REPAIR_MAX_SLEW_PCT`/`GRT_DESIGN_REPAIR_MAX_SLEW_PCT`,
`docs/uart-technical-report.md` §4.2) does not straightforwardly scale
up. Applying the identical mechanism to `picorv32` (19,058 instances,
6,316 nets flagged for repair) reproducibly killed the OpenROAD process
via the Linux OOM killer, independently confirmed three separate times:

| Attempt | Margin values | `OPENROAD_THREADS` | Confirmed resident memory at kill |
|---|---|---|---|
| 6 | slew 40 / cap 40 / GRT-slew 30 / GRT-cap 30 | 8 | (crashed identically; not independently re-checked against kernel log, but see attempts 7–8) |
| 7 | slew 25 / cap default / GRT-slew 15 | 8 | ~19.9 GB (`anon-rss:20885252kB`) |
| 8 | slew 25 / cap default / GRT-slew 15 | **4** | ~19.8 GB (`anon-rss:20772264kB`) |

Attempts 7 and 8 used **different thread counts and produced
near-identical memory footprints at the moment of the kill** — the
strongest evidence available that this is a per-design, per-repair-scope
memory requirement, not a threading artifact. Attempt 6 was not
independently re-confirmed via kernel log with the same rigor as 7 and
8 (it was checked after the fact, once the pattern was already
understood, and the log entry for that specific kill was not separately
isolated) — this report states that plainly rather than implying all
three were verified to the same standard.

**Practical rule:** don't assume a slew/cap-repair fix that worked on a
small design (`uart_top`, 290 cells) will simply cost proportionally
more RAM on a design ~65x larger (19,058 cells) — in this case it cost
enough to exceed 23GB outright. Before attempting this class of repair
on a large design, either (a) budget substantially more RAM than the
design's overall flow otherwise seems to need (this design's *other*
stages peaked under 3GB — see §7), or (b) accept the residual violations
locally and defer the repair to a machine known to have sufficient
headroom, which is precisely what this exercise did (§5.8, deferring to
the planned cloud run, §9).

### 6.4 Process discipline: don't delete a result before you're sure you're done with it

Not a LibreLane finding, but worth stating with the same directness as
the technical ones, because it actually happened (§5.5): the first
clean result obtained in this exercise was deleted (as part of the
routine `rm -rf runs/` between attempts) before its artifacts were
copied anywhere durable, and had to be regenerated from scratch. The
fix applied here was simple — re-run the exact configuration and confirm
identical metrics before trusting the regenerated result — but the
mistake was avoidable, and a reader repeating this kind of exploratory,
many-attempts session should preserve (copy out, don't just view) a
result the moment it looks like the best one so far, not after deciding
to move on to the next experiment.

## 7. Resource Profile Summary

Consolidated from the resource logs taken during §5's attempts (`docker
stats` + `free -h`, sampled at 20-second intervals):

| Phase | Peak observed RAM | Peak observed CPU |
|---|---|---|
| Full flow, 1 thread (attempt 1) | ~763 MiB | ~101% (1 logical core) |
| Full flow, 8 threads, no repair-margin override (attempts 2–5, 9) | ~1.4–2.8 GB | ~796% (~8 logical cores) |
| `OpenROAD.RepairDesignPostGPL` with explicit slew/cap margins on 6,316 nets (attempts 6–8) | **~19.8–19.9 GB (OOM-killed)** | not meaningfully measured before the kill |

The contrast in the last row against everything above it is the single
most important number in this report for sizing the planned cloud VM
(§9): the bulk of this design's flow is comfortably sub-3GB, but one
specific, optional repair step is not — and a sizing plan based only on
the "everything else" number would have been dangerously wrong for the
one step that actually mattered.

## 8. Reproducing This Result

```bash
# From the repo root
docker compose -f docker/docker-compose.yml build

# The clean (attempt 5 / 9) result:
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/picorv32 \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd designs/picorv32/config.yaml

# Portable across machines of different core counts (see §9):
CORES=$(nproc)
docker compose -f docker/docker-compose.yml run --rm \
  --workdir /workspace/designs/picorv32 \
  librelane-dev --skip \
  librelane -p sky130A -s sky130_fd_sc_hd \
  -c OPENROAD_THREADS=$CORES -c STA_THREADS=$CORES \
  designs/picorv32/config.yaml
```

`designs/picorv32/config.yaml` as committed reflects attempt 5/9's clean
configuration (`CLOCK_PERIOD: 30`, `SYNTH_STRATEGY: "DELAY 4"`,
`OPENROAD_THREADS: 8`, `STA_THREADS: 9`), with the slew/cap margin
attempts from §5.6–5.8 deliberately **not** carried into the committed
file — they are documented here as a record of what was tried and why
it failed on this machine, not as something to blindly re-apply.

## 9. What's Next: the Cloud Run

This report covers the local exploration only. As of this writing, the
planned cloud burst (`docs/picorv32-cloud-burst-plan.md`,
`docker/cloud-burst/`) has completed a rehearsal phase (a Nano-tier
Linode instance, using `counter3` as a lightweight stand-in payload to
validate SSH/upload/Docker/build mechanics without needing this design's
resource footprint) but not yet the real run. The immediate next step,
already in progress: resizing that same instance to 2 vCPUs specifically
to verify — on the actual target cloud infrastructure, not just locally
— that the threading fix from §6.1 genuinely results in multi-core
utilization there too, before committing to the full-sized (50-core /
128GB, per thầy's latest sizing) paid run. The `-c OPENROAD_THREADS=$(nproc)`
override pattern in §8 exists specifically so the identical command
works unmodified at 2 cores, and later at 50, without hand-editing
`config.yaml` for each machine size — itself a small methodological
finding from this same week of work, arrived at while preparing for
this section.

Once run at full scale, this report should be extended (not replaced)
with: whether the §6.3 memory ceiling is actually cleared with
substantially more RAM available (closing the remaining max-slew/max-cap
violations for the first time); a real, systematic GDS-hash determinism
check across N parallel replicas (the informal single-repeat check in
§5.9 was suggestive, not the real test); and actual wall-clock/cost data
for the full-sized run, which is the number that will most directly
inform whether `docs/OPEN_SILICON_KICKOFF.md` §5.2's RAM-sizing guess
was right, wrong, or in what direction.

## References

- `docs/OPEN_SILICON_KICKOFF.md` — program roadmap, §4 (design ladder)
  and §5.2 (regression-server sizing question this report speaks to)
- `docs/decisions/ADR-OS-007-rent-compute-before-buying.md` — why a
  cloud burst instead of owned hardware
- `docs/counter3-technical-report.md`, `docs/uart-technical-report.md` —
  the program's first two designs, and the `uart` slew-margin fix this
  report's §5.6–5.8 attempted to scale up
- `wiki/librelane-threading-and-timing-strategy.md` — the condensed,
  agent-facing version of §6's findings
- `wiki/librelane-metrics-json.md`, `wiki/librelane-config-for-tiny-designs.md`,
  `wiki/uart-signoff-sizing-and-slew-margin.md` — prior toolchain
  gotchas this exercise built on
- `docs/picorv32-cloud-burst-plan.md`, `docker/cloud-burst/` — the
  in-progress cloud run this local work was preparing for
- `backlog.md` — running log, including the overnight session this
  report documents
- picorv32 upstream: `github.com/YosysHQ/picorv32`
- LibreLane documentation: `librelane.readthedocs.io`

## Changelog

| Version | Date | Change |
|---|---|---|
| v1.0 | 2026-09-17 | First version, covering the local exploration (attempts 1-9) ahead of the planned cloud run. |
