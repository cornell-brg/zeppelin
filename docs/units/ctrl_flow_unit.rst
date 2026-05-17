Control Flow Unit (CFU)
==========================================================================

The control flow unit arbitrates between control flow redirect notifications
from multiple sources (execute units, the decode-issue unit) and selects a
single winner each cycle. The winning redirect is broadcast to the fetch unit
(to restart instruction fetching at the correct target) and to any other units
that must react to a pipeline redirect. In processors with branch prediction,
the unit also forwards branch predictor update signals (``bp_update_val``,
``taken``, ``pc``, ``target``) from the winning source so that the fetch unit's
branch predictor can learn from resolved branches and jumps.

All control flow unit variants operate on the ``ControlFlowNotif`` interface,
which carries ``redirect_val`` (fetch must redirect), ``bp_update_val``
(branch/JAL resolution data is valid for BP update), ``seq_num``, ``pc``,
``target``, and ``taken``.

CtrlFlowUnit L1
--------------------------------------------------------------------------

The Level 1 Control Flow Unit (``CtrlFlowUnitL1``) arbitrates between
``p_num_arb`` redirect sources using a binary-tree structure of pairwise
``CtrlFlowUnitL1Helper`` arbiters. Each helper selects the older of two
notifications based on their sequence numbers, using the ``SeqAge`` module for
wrap-around-safe age comparison. The ``SeqAge`` module tracks age via the
single-lane ``CommitNotif`` interface.

When only one source is valid, it wins unconditionally. When both sources are
valid, the older notification (the one with the earlier sequence number) is
selected. The binary tree is built at elaboration time: leaf nodes connect to
the ``arb`` interface array, and each level halves the number of candidates until
a single winner emerges at the root. Unused leaf slots (when ``p_num_arb`` is
not a power of two) are zero-filled with ``redirect_val = 0``.

For the trivial ``p_num_arb == 1`` case, the single source passes through
directly with no arbitration hardware.

CtrlFlowUnit L1 Chain
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``CtrlFlowUnitL1Chain`` is a variant of the L1 unit that uses a linear
chain instead of a binary tree. Starting from source 0, each stage compares
the running winner against the next source and carries the older one forward.
This produces a longer combinational path (O(n) instead of O(log n)) but uses
simpler wiring and may be preferred when the number of sources is small.

CtrlFlowUnit L2
--------------------------------------------------------------------------

The Level 2 Control Flow Unit (``CtrlFlowUnitL2``) extends L1 with support for
a superscalar backend. Instead of the single-lane ``SeqAge`` module, L2 uses
``SSSeqAge`` to track the oldest committed sequence number across
``p_num_be_lanes`` commit lanes. This allows correct wrap-around-safe age
comparison when multiple instructions commit per cycle.

The arbitration structure is the same binary tree of pairwise helpers as L1, but
the ``CtrlFlowUnitL2Helper`` receives the ``oldest_seq_num`` directly from
``SSSeqAge`` rather than instantiating its own age tracker. A single ``SSSeqAge``
instance is shared across all helpers in the tree.

CtrlFlowUnit L3
--------------------------------------------------------------------------

The Level 3 Control Flow Unit (``CtrlFlowUnitL3``) extends L2 with a decoupled
grant output for the decode-issue unit, which is necessary when the DIU's
control flow publisher (``DIUCtrlFlowPublisher``) is combinational. It produces
two grant outputs:

- **``gnt``:** The full arbitration result across all ``p_num_arb`` sources,
  broadcast to the fetch unit and other subscribers.

- **``gnt_excl``:** The arbitration result excluding the DIU source (identified
  by ``p_diu_idx``), connected to the DIU's own ``ctrl_flow_sub`` input. This
  breaks the combinational loop that would otherwise form: the DIU publishes a
  redirect combinationally, the control flow unit arbitrates it, and the result
  feeds back into the DIU.

Both grants use the same ``SSSeqAge`` instance for age tracking. The full grant
uses a binary tree of ``CtrlFlowUnitL3Helper`` arbiters across all sources. The
excluded grant uses a second binary tree that omits the DIU source. When
``p_num_arb == 2`` (the common case with one XU source and one DIU source),
``gnt_excl`` is a zero-cost passthrough of the single non-DIU source, requiring
no additional arbitration hardware.

The L3 helper also passes through the full ``ControlFlowNotif`` fields
(``pc``, ``target``, ``taken``, ``bp_update_val``) from the winning source,
enabling the branch predictor to receive update information through the
arbitrated grant.
