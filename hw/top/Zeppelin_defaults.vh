//========================================================================
// Zeppelin_defaults.vh
//========================================================================
// Default parameter defines for Zeppelin. Overridable via -D flags
// (e.g., from ASIC flow YAML configs).
//
// Included by Zeppelin_sim.v, ZeppelinASICWrap.v, and
// Zeppelin_test_suites.vh.

`ifndef _ZEPPELIN_DEFAULTS_VH
`define _ZEPPELIN_DEFAULTS_VH

`ifndef P_OPAQ_BITS
  `define P_OPAQ_BITS               8
`endif
`ifndef P_SEQ_NUM_BITS
  `define P_SEQ_NUM_BITS            5
`endif
`ifndef P_NUM_PHYS_REGS
  `define P_NUM_PHYS_REGS           38
`endif
`ifndef P_NUM_FE_LANES
  `define P_NUM_FE_LANES            2
`endif
`ifndef P_NUM_BE_LANES
  `define P_NUM_BE_LANES            2
`endif
`ifndef P_IQ_DEPTH
  `define P_IQ_DEPTH                2
`endif
`ifndef P_RECLAIM_WIDTH
  `define P_RECLAIM_WIDTH           `P_NUM_BE_LANES
`endif
`ifndef P_MAX_IN_FLIGHT
  `define P_MAX_IN_FLIGHT           2*`P_NUM_FE_LANES
`endif
`ifndef P_F_INTF_FIFO_DEPTH
  `define P_F_INTF_FIFO_DEPTH       1
`endif
`ifndef P_ALU_D_INTF_FIFO_DEPTH
  `define P_ALU_D_INTF_FIFO_DEPTH   1
`endif
`ifndef P_MUL_D_INTF_FIFO_DEPTH
  `define P_MUL_D_INTF_FIFO_DEPTH   1
`endif
`ifndef P_MEM_D_INTF_FIFO_DEPTH
  `define P_MEM_D_INTF_FIFO_DEPTH   1
`endif
`ifndef P_CTRL_D_INTF_FIFO_DEPTH
  `define P_CTRL_D_INTF_FIFO_DEPTH  1
`endif
`ifndef P_X_INTF_FIFO_DEPTH
  `define P_X_INTF_FIFO_DEPTH       1
`endif
`ifndef P_ALL_IQ_IN_ORDER
  `define P_ALL_IQ_IN_ORDER         1
`endif
`ifndef P_NUM_ALUS
  `define P_NUM_ALUS                `P_NUM_BE_LANES
`endif
`ifndef P_NUM_MULS
  `define P_NUM_MULS                `P_NUM_BE_LANES
`endif
`ifndef P_PIPE_BYPASS
  `define P_PIPE_BYPASS             1
`endif
`ifndef P_MULDIVREM_SEL
  `define P_MULDIVREM_SEL           1
`endif
`ifndef P_ENABLE_BRANCH_PRED
  `define P_ENABLE_BRANCH_PRED      1
`endif
`ifndef P_BTB_ENTRIES
  `define P_BTB_ENTRIES             1
`endif
`ifndef P_BTB_WAYS
  `define P_BTB_WAYS                `P_BTB_ENTRIES
`endif

`endif // _ZEPPELIN_DEFAULTS_VH
