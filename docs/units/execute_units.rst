Execute Units (XU)
==========================================================================

Execute units sit between the decode-issue unit and the writeback-commit unit,
connected via the ``D__XIntf`` (input) and ``X__WIntf`` (output) interfaces.
Each execute unit receives decoded instructions with resolved operands from an
issue queue, performs its computation, and drives the result to the writeback
stage. Execute units are specialized by function: arithmetic/logic, control flow,
memory, and multiply/divide/remainder.

All execute units at level 6 and above include a bypass FIFO at the ``D__XIntf``
input (parameterized by ``p_d_intf_fifo_depth``) that decouples the issue queue
from the execute datapath. The FIFO pops when the downstream ``X__WIntf`` is
ready and pushes when a valid instruction arrives from the issue queue. Each unit
also carries physical register specifiers (``preg``, ``ppreg``) through the
pipeline for writeback-commit to use during commit and free-list reclamation.

Arithmetic/Logic Unit: ALUL6
--------------------------------------------------------------------------

The ALU (``ALUL6``) is a single-cycle combinational execute unit that handles
all integer arithmetic and logic operations: ``ADD``, ``SUB``, ``AND``, ``OR``,
``XOR``, ``SLT``, ``SLTU``, ``SRA``, ``SRL``, ``SLL``, ``LUI``, and ``AUIPC``.
The input bypass FIFO buffers instructions from the issue queue; on each cycle
that the FIFO is non-empty and the writeback interface is ready, the head
instruction's operands are fed into a combinational case-select that produces the
result. ``AUIPC`` adds the PC to the immediate; ``LUI`` passes the immediate
directly. The write-enable (``wen``) is always asserted since all ALU
instructions write a destination register.

Control Flow Execute Unit: ControlFlowUnitL5 and L6
--------------------------------------------------------------------------

The control flow execute unit resolves conditional branch instructions and
publishes redirect notifications via the ``ControlFlowNotif`` interface. In
processors where JAL/JALR are handled by the decode-issue unit
(``DIUCtrlFlowPublisher``), only conditional branches (BEQ, BNE, BLT, BGE,
BLTU, BGEU) reach this unit.

**ControlFlowUnitL5** uses a simple registered pipeline stage (no input FIFO).
It evaluates the branch condition by comparing ``op1`` and ``op2`` and publishes
a redirect on ``ctrl_flow.redirect_val`` when the branch is taken. The ``target``
is always ``PC + imm``. The link-register write (``PC + 4``) is driven for
JAL/JALR instructions. A ``ctrl_flow_sent`` flag prevents re-publishing the same
redirect on subsequent cycles before the instruction is consumed by writeback.

**ControlFlowUnitL6** extends L5 with a bypass FIFO at the D interface input and
support for branch prediction. It evaluates the branch condition identically but
uses the ``predicted_taken`` field (propagated from the fetch unit via the issue
queue) to detect mispredictions. A redirect is published only when the actual
outcome differs from the prediction (``should_branch != predicted_taken``). The
unit also asserts ``bp_update_val`` on every conditional branch (regardless of
whether it mispredicted) so that the branch predictor can update its state. The
``taken`` signal carries the actual branch direction, and ``target`` carries
``PC + imm`` (the branch destination); the redirect consumer uses ``taken`` to
determine whether to redirect to the target or the fall-through address.

Load-Store Unit: LoadStoreUnitL7
--------------------------------------------------------------------------

The load-store unit (``LoadStoreUnitL7``) is a two-stage pipelined execute unit
that handles all memory operations (LB, LH, LW, LBU, LHU, SB, SH, SW) via the
``MemIntf`` interface.

**Stage 1 (Request):** The input bypass FIFO holds decoded memory instructions.
When the head instruction is valid, the memory interface is ready, and the
stage 2 FIFO has space, the unit computes the effective address (``op1 + op2``),
word-aligns it, and issues the memory request. For sub-word operations, the
byte offset within the word is used to shift the store data and compute the
appropriate byte strobe mask (``strb``). The byte offset and instruction metadata
(sequence number, write address, micro-op, physical registers) are pushed into a
stage 2 FIFO to accompany the memory response when it returns.

**Stage 2 (Response):** A ``stage2_fifo`` (depth rounded to the next power of 2
from ``p_num_in_flight``) buffers the metadata for all in-flight requests. A
stage 2 register holds the metadata for the currently-awaited response. When the
memory response arrives, the unit uses the stored byte offset to extract and
shift the correct bytes from the response data, then applies sign- or
zero-extension based on the micro-op (sign-extend for LB/LH, zero-extend for
LBU/LHU, full word for LW). Store operations drive ``wen = 0`` since they do
not write a destination register.

The stage 2 FIFO supports a bypass path: when the FIFO is empty and a push
fires simultaneously, the metadata is routed directly into the stage 2 register
on the next cycle, avoiding the extra latency of writing to and reading from the
FIFO array. This preserves low latency for the common single-in-flight case
while still supporting multiple outstanding requests via the FIFO when traffic
backs up.

Multiply/Divide/Remainder Units
--------------------------------------------------------------------------

Three variants implement the RV32M extension operations (MUL, MULH, MULHSU,
MULHU, DIV, DIVU, REM, REMU), all sharing the same ``D__XIntf`` / ``X__WIntf``
interface:

IterativeMulDivRemL7
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The iterative unit (``IterativeMulDivRemL7``) uses a multi-cycle state machine
with five states: ``IDLE``, ``SWAP_SIGN``, ``CALC``, ``RESTORE_SIGN``, and
``DONE``. On each ``CALC`` cycle, the ``IterativeMulDivRemStepL7`` submodule
advances the computation by one iteration:

- **Multiplication:** Shift-and-add algorithm. ``a`` shifts left, ``b`` shifts
  right; when the LSB of ``b`` is set, ``a`` is accumulated into the result.
  Completes when ``b`` reaches zero.

- **Division/Remainder:** Restoring division. On each step, if ``|a| >= b`` the
  divisor is subtracted and the quotient bit is accumulated. The ``b_shift``
  register tracks the current quotient bit position, shifting right each cycle
  until zero. For remainder, the result is simply the final value of ``a``.

Signed operations use a ``SWAP_SIGN`` state to negate ``op2`` when it is
negative (for DIV/REM), and a ``RESTORE_SIGN`` state to correct the result sign
afterward. The unit handles divide-by-zero (returns all-ones for DIV/DIVU,
dividend for REM/REMU) and signed overflow (``-2^31 / -1``) as special cases.
The ``D.rdy`` signal deasserts while the computation is in progress, stalling
the issue queue.

SingleCycleMulDivRemL7
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The single-cycle unit (``SingleCycleMulDivRemL7``) computes all MUL/DIV/REM
operations in one cycle using a combinational datapath. It shares a single
hardware multiplier between multiplication and remainder computation: for MUL
variants, the multiplier computes ``op1 * op2`` directly with appropriate sign
extension; for REM variants, the multiplier computes ``quotient * divisor`` so
that the remainder can be derived as ``dividend - product``. Division uses a
combinational ``/`` operator. The same divide-by-zero and overflow edge cases
are handled. This variant has the highest throughput (one result per cycle) but
the longest combinational path.

SingleCycleMulIterativeDivRemL7
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The hybrid unit (``SingleCycleMulIterativeDivRemL7``) combines a single-cycle
multiplier for MUL/MULH/MULHSU/MULHU with an iterative divider
(``IterativeDivRemStepL7``) for DIV/DIVU/REM/REMU. Multiplications complete in
one cycle with full throughput, while divisions iterate over multiple cycles
using the same restoring-division algorithm as the fully iterative variant. This
provides the best area/timing trade-off: the critical multiplier path is short,
and the slower division operations (which are less frequent) amortize over
multiple cycles.

Execute Queue: ExQueue
--------------------------------------------------------------------------

The ``ExQueue`` module is an optional output buffer that can be placed between
an execute unit's ``X__WIntf`` output and the writeback-commit unit's input. It
wraps a ``Fifo`` with a bypass path: when the FIFO is empty, incoming data
passes directly to the output (zero additional latency); when the FIFO is
non-empty, data is read from the FIFO head. This allows the execute unit to
continue producing results even when the writeback-commit unit temporarily
stalls, at the cost of additional buffering depth (parameterized by
``p_depth``).
