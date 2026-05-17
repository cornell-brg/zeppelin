# Zeppelin Line Trace

How to read the per-cycle line trace produced by `Zeppelin_sim` and
`ZeppelinTestHarness` when run with `+verbose` (stdout) or
`+dump-line-traces=<file>` (file dump). The first line printed is a
**header line**; every subsequent line is one cycle, with columns aligned
character-for-character to the header.

## Plusargs cheat sheet

- `+verbose` / `+v` -- print the trace to stdout
- `+dump-line-traces=<file>` -- write the trace to a file
- `+s=<filter>` -- run only test cases matching `<filter>` (unit tests only)
- `+test-suite=<N>` -- run a specific test suite (unit tests only)

`+trace-level=N` is still parsed for backwards compatibility but is now a
no-op; the trace always uses the compact format.

## Top-level structure

```
FU | DIU | ALU | MUL | LSU | CTRL | WCU
```

Each header label is a single short string (typically ≤ 3 characters);
columns with multiple lanes/pipes (DIU, ALU, MUL, WCU) use one shared
label spanning the whole group, with lanes joined by ` ; ` inside.
Labels:

- FU sub-stages: `req` / `rsp`
- DIU: `DIU` (single label spanning all lanes)
- ALU: `ALU` (single label; per-lane width = seq num only, no marker)
- MUL: `MUL` (single label spanning all pipes)
- LSU sub-stages: `LSQ` / `LSS`
- CTRL: `CTL`
- WCU sub-stages: `arb` / `cmt`

Four separator strings with distinct meanings:

- ` | ` (pipe) separates **stages** at the top level (i.e. the major
  pipeline stages: FU / DIU / ALU group / MUL group / LSU / CTRL / WCU).
- ` ; ` (semicolon) separates **superscalar lanes / pipes** within a
  module (FU response lanes, DIU lanes, ALU pipes, MUL pipes, WCU
  per-side lanes).
- ` > ` separates **sub-stages** of a request/response pipeline within
  a module (FU req > rsp, LSU LSQ > LSS).
- ` \ ` (backslash) separates the WCU's **arbitrate** and **commit**
  sides inside its column.

The architectural commit stream is now folded into the WCU column's
right-hand sub-column; there is no longer a standalone `INST[i]` block
past `||`.

Every column is a **fixed width** computed at compile time from the design
parameters. Idle columns are filled with spaces of that exact width.

## Stall / status markers

Markers appear suffixed to the column body (after the seq num /
disassembly):

- `(#)` -- the instruction occupies the stage but is *not* advancing to
  the next stage this cycle (back-pressure, structural hazard, waiting on
  memory, etc.).
- `(#N)` -- *(DIU only)* same as `(#)` but `N` identifies the first
  failing instruction-check stage for that lane: `1` = validity (S1),
  `2` = control-instruction ordering (S2), `3` = physical-register
  allocation (S3), `4` = structural / crossbar-routing hazard (S4). A
  bare `(#)` (no number) means all four checks passed but the lane still
  isn't dispatching this cycle (e.g. the dispatch FIFO is full).
- `(X)` -- *(DIU only)* the instruction window entry is marked
  `INST_STATUS_DISPATCHED` (already dispatched on a prior cycle, lingering
  in the window until siblings drain) or `INST_STATUS_INVALID` (squashed
  / dropped).
- `(S)` -- a control-flow **squash** is being published this cycle.
  - On a DIU lane: the dispatching `jal`/`jalr` in that lane is the
    redirect source (`ctrl_flow_pub.redirect_val` & this lane is the
    oldest control inst).
  - On the CTRL execute column: the resident branch is mispredicted and
    publishing a redirect (`ctrl_flow.redirect_val`).

A column going filled -> blank between cycles means the resident
instruction advanced to the next stage (or was squashed). A column going
filled -> filled+`(#)` means it stalled.

## Per-module breakdown

### FU -- `FetchUnit`

Two sub-columns separated by ` > `: the request being sent to IMEM and
the response producing decoded fetch packets.

```
FU req       > FU resp
<addr>       > <addr>: <s0> | <s1> | ... | <sN>
```

- `req` (12 chars): hex address being requested from IMEM, plus ` (#)` if
  the request is held but not accepted (`mem.req.val & !mem.req.rdy`).
  Blank if no request this cycle.
- `resp`: when the response is valid: `<resp_addr>: <s0> | <s1> | ...`,
  one seq per FE lane. ` (#)` is appended when the response is held but
  the DIU is not ready (`!D_rdy_all`). If the packet was squashed in
  flight, the resp side is filled with `X` characters. Blank when no
  response this cycle.

### DIU[i] -- `DecodeIssueUnit`

One sub-column per FE lane, joined by ` | `. Shows the head of the issue
window for that lane.

```
DIU[0]                                 | DIU[1]                                 | ...
<seq>: <disassembly (left-padded to 30 chars)>
```

Examples: `00: addi   x3, x3, -848`, `02: lw     x5, 0(x3)`. The disasm
is padded to a fixed width (30 chars) and may be followed by ` (#)` or
` (X)` per the marker rules above.

### ALU -- `ALU`

One column per ALU pipe (`p_num_alus`), e.g. seq `01`. Idle: blank.
` (#)` appears when the ALU output is held by downstream back-pressure.

### MUL -- `IterativeMulDivRem` / `SingleCycleMulDivRem` / `SingleCycleMulIterativeDivRem`

One column per multiplier pipe (`p_num_muls`).

Body shown per cycle:
- blank when IDLE,
- `CC` while calculating (iterative paths only: SWAP_SIGN / CALC /
  RESTORE_SIGN),
- the resident seq num when `DONE`,
- `##` on **output stall** (`W.val & !W.rdy` while DONE).

The single-cycle mul path goes IDLE -> DONE in one step and never
shows `CC`.

### LSU -- `LoadStoreUnit`

Two sub-columns separated by ` > `: stage 1 (request being sent toward
DMEM) and stage 2 (waiting on / receiving the response). Each side
shows the resident seq and ` (#)` when held back.

```
LSQ    > LSS
<seq>  > <seq>
```

### CTRL -- `ControlFlowUnit`

Single column showing the seq number of the resident branch/jump uop,
plus ` (#)` if the writeback is held.

### WCU -- `WritebackCommitUnit`

Two sub-column groups separated by ` > `:

- **Left** (`WCU arb[i]`): one sub-column per BE lane, joined by ` | `.
  Shows the seq the lane is being arbitrated to commit *this cycle*
  (`Ex_msg_sel[i]`, the post-arbitration mux output).
- **Right** (`WCU cmt[i]`): one sub-column per BE lane, joined by ` | `.
  Shows the seq actually committing this cycle (`commit[i].seq_num`,
  driven from the ROB output).

This subsumes the old standalone `INST[i]` column.

## Worked example (3FE / 3BE config)

Header + a few cycles (truncated for width):

```
FU req       > FU resp                    I DIU[0]                                 | DIU[1]                                 | DIU[2]                                 I ALU    I ALU    I ALU    I MUL    I MUL    I MUL    I LSQ    > LSS    I CTRL   I WCU arb[0] | WCU arb[1] | WCU arb[2] > WCU cmt[0] | WCU cmt[1] | WCU cmt[2]
00000218     > 0000020c:    |    |    (#) I 00: auipc  x3, 2                       | 01: addi   x3, x3, -848            (#) | 02: addi   x1, x0, 0               (#) I        I        I        I        I        I        I        >        I        I            |            |            >            |            |
             > 0000020c: 03 | 04 | 05     I 00: auipc  x3, 2                   (X) | 01: addi   x3, x3, -848                | 02: addi   x1, x0, 0                   I 00     I        I        I        I        I        I        >        I        I 00         |            |            >            |            |
00000224     > 00000218: 06 | 07 | 08     I 03: addi   x2, x0, 0                   | 04: addi   x4, x0, 0                   | 05: addi   x5, x0, 0                   I 01     I 02     I        I        I        I        I        >        I        I 01         | 02         |            > 00         |            |
```

Reading the markers:

- The first row's FU response shows `   |    |    (#)`: the response is
  held back this cycle (lanes 1 and 2 of DIU are stalled), so no seq
  numbers are allocated yet.
- DIU lane 0's `(X)` on the second row: the entry is now marked
  DISPATCHED (it advanced to ALU last cycle but the window hasn't popped
  because lanes 1/2 still have work).
- WCU arb[0] = `00`, WCU cmt[0] = blank: instruction `00` is being
  arbitrated to commit *this cycle*; nothing was committed *this cycle*
  yet (commits show one cycle later as the ROB drains).

## Source pointers

- Top-level trace assembly: [hw/top/Zeppelin.v](Zeppelin.v)
  (`function trace`, `function trace_header`).
- Sim wrapper: [hw/top/sim/Zeppelin_sim.v](sim/Zeppelin_sim.v) and
  [hw/top/test/ZeppelinTestHarness.v](test/ZeppelinTestHarness.v).
- Per-module trace formatting:
  - [FetchUnit.v](../fetch/FetchUnit.v)
  - [DecodeIssueUnit.v](../decode_issue/DecodeIssueUnit.v)
  - [ALU.v](../execute/ALU.v)
  - [IterativeMulDivRem.v](../execute/IterativeMulDivRem.v)
  - [SingleCycleMulDivRem.v](../execute/SingleCycleMulDivRem.v)
  - [LoadStoreUnit.v](../execute/LoadStoreUnit.v)
  - [ControlFlowUnit.v](../execute/ControlFlowUnit.v)
  - [WritebackCommitUnit.v](../writeback_commit/WritebackCommitUnit.v)
