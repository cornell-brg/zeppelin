//========================================================================
// Zeppelin.v
//========================================================================
// A top-level implementation of the Zeppelin processor with support for
// RV32IM (no exceptions) and superscalar issue and backend

`ifndef HW_TOP_ZEPPELIN_V
`define HW_TOP_ZEPPELIN_V

`include "defs/UArch.v"
`include "hw/fetch/FetchUnit.v"
`include "hw/decode_issue/DecodeIssueUnit.v"
`include "hw/execute/ALU.v"
`include "hw/execute/IterativeMulDivRem.v"
`include "hw/execute/SingleCycleMulIterativeDivRem.v"
`include "hw/execute/SingleCycleMulDivRem.v"
`include "hw/execute/LoadStoreUnit.v"
`include "hw/execute/ControlFlowUnit.v"
`include "hw/ctrl_flow/CtrlFlowUnit.v"
`include "hw/writeback_commit/WritebackCommitUnit.v"
`include "hw/util/TraceHeader.v"
`include "hw/util/F__DDelay.v"
`include "hw/util/D__XDelay.v"
`include "hw/util/X__WDelay.v"
`include "intf/MemIntf.v"
`include "intf/F__DIntf.v"
`include "intf/D__XIntf.v"
`include "intf/X__WIntf.v"
`include "intf/CompleteNotif.v"
`include "intf/CommitNotif.v"
`include "intf/ControlFlowNotif.v"
`include "intf/InstTraceNotif.v"
`include "hw/top/Zeppelin_defaults.vh"

module Zeppelin #(
  parameter p_opaq_bits               = `P_OPAQ_BITS,
  parameter p_seq_num_bits            = `P_SEQ_NUM_BITS,
  parameter p_num_phys_regs           = `P_NUM_PHYS_REGS,
  parameter p_num_fe_lanes            = `P_NUM_FE_LANES,
  parameter p_num_be_lanes            = `P_NUM_BE_LANES, // must be <= 2**p_seq_num_bits (ROB depth)
  parameter p_iq_depth                = `P_IQ_DEPTH,
  parameter p_reclaim_width           = p_num_be_lanes,
  parameter p_max_in_flight           = `P_MAX_IN_FLIGHT,
  parameter p_f_intf_fifo_depth       = `P_F_INTF_FIFO_DEPTH,
  parameter p_x_intf_fifo_depth       = `P_X_INTF_FIFO_DEPTH,
  parameter p_alu_d_intf_fifo_depth   = `P_ALU_D_INTF_FIFO_DEPTH,
  parameter p_mul_d_intf_fifo_depth   = `P_MUL_D_INTF_FIFO_DEPTH,
  parameter p_mem_d_intf_fifo_depth   = `P_MEM_D_INTF_FIFO_DEPTH,
  parameter p_ctrl_d_intf_fifo_depth  = `P_CTRL_D_INTF_FIFO_DEPTH, // must be 1 - 1-cycle brx resolution
  parameter p_num_alus                = `P_NUM_ALUS,
  parameter p_num_muls                = `P_NUM_MULS,
  parameter p_num_pipes               = p_num_alus + p_num_muls + 2,
  parameter p_pipe_bypass             = `P_PIPE_BYPASS, // 1 = bypass all pipes, 0 = bypass ctrl pipe only
  parameter p_muldivrem_sel           = `P_MULDIVREM_SEL, // 0 = fully iterative, 1 = single-cycle mul + iterative div/rem, 2 = fully single-cycle
  parameter p_all_iq_in_order         = `P_ALL_IQ_IN_ORDER,
  parameter p_enable_branch_pred      = `P_ENABLE_BRANCH_PRED,
  parameter p_btb_entries             = `P_BTB_ENTRIES,
  parameter p_btb_ways                = p_btb_entries,

  // Simulation-only backpressure parameters (ignored in synthesis)
  // Packed arrays: 8 bits per lane/pipe. Stall 1 cycle every N; 0 = off.
  parameter [p_num_fe_lanes*8-1:0] p_sim_f2d_bp = '0,
  parameter [p_num_pipes*8-1:0]    p_sim_d2x_bp = '0,
  parameter [p_num_pipes*8-1:0]    p_sim_x2w_bp = '0 
) (
  input logic clk,
  input logic rst,

  //----------------------------------------------------------------------
  // Instruction Memory
  //----------------------------------------------------------------------

  MemIntf.client inst_mem,

  //----------------------------------------------------------------------
  // Data Memory
  //----------------------------------------------------------------------

  MemIntf.client data_mem,

  //----------------------------------------------------------------------
  // Instruction Trace
  //----------------------------------------------------------------------

  InstTraceNotif.pub inst_trace [p_num_be_lanes]
);

  localparam p_phys_addr_bits = $clog2( p_num_phys_regs );

  //----------------------------------------------------------------------
  // Interfaces
  //----------------------------------------------------------------------

  F__DIntf #(
    .p_seq_num_bits (p_seq_num_bits)
  ) f__d_intfs[p_num_fe_lanes]();

  D__XIntf #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) d__x_intfs[p_num_pipes]();

  X__WIntf #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) x__w_intfs[p_num_pipes]();

  ControlFlowNotif #(
    .p_seq_num_bits (p_seq_num_bits)
  ) ctrl_flow_arb_notif [2]();

  ControlFlowNotif #(
    .p_seq_num_bits (p_seq_num_bits)
  ) ctrl_flow_gnt_notif();

  ControlFlowNotif #(
    .p_seq_num_bits (p_seq_num_bits)
  ) ctrl_flow_gnt_excl_notif();

  CompleteNotif #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) complete_notif [p_num_be_lanes]();

  CommitNotif #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) commit_notif [p_num_be_lanes]();

  //----------------------------------------------------------------------
  // Delayed Interfaces
  //----------------------------------------------------------------------
  // Intermediate interfaces for simulation-only delay injection between
  // major pipeline stages. Downstream modules connect to these.

  F__DIntf #(
    .p_seq_num_bits (p_seq_num_bits)
  ) f__d_del[p_num_fe_lanes]();

  D__XIntf #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) d__x_del[p_num_pipes]();

  X__WIntf #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) x__w_del[p_num_pipes]();

  logic [4:0] unused_complete_waddr [p_num_be_lanes];

  genvar i;
  generate
    for( i = 0; i < p_num_be_lanes; i++ ) begin
      assign inst_trace[i].pc         = commit_notif[i].pc;
      assign inst_trace[i].waddr      = commit_notif[i].waddr;
      assign inst_trace[i].wdata      = commit_notif[i].wdata;
      assign inst_trace[i].wen        = commit_notif[i].wen;
      assign inst_trace[i].val        = commit_notif[i].val;
      assign inst_trace[i].seq_num    = commit_notif[i].seq_num;
      assign unused_complete_waddr[i] = complete_notif[i].waddr;
    end
  endgenerate

  //----------------------------------------------------------------------
  // Delay / Pass-through
  //----------------------------------------------------------------------

`ifndef SYNTHESIS

  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin: F2D_DELAY
      F__DDelay #(
        .p_seq_num_bits (p_seq_num_bits),
        .p_bp_interval  (p_sim_f2d_bp[i*8 +: 8])
      ) f2d_delay (
        .clk (clk),
        .rst (rst),
        .up  (f__d_intfs[i]),
        .dn  (f__d_del[i])
      );
    end
  endgenerate

  generate
    for( i = 0; i < p_num_pipes; i++ ) begin: D2X_DELAY
      D__XDelay #(
        .p_seq_num_bits   (p_seq_num_bits),
        .p_phys_addr_bits (p_phys_addr_bits),
        .p_bp_interval    (p_sim_d2x_bp[i*8 +: 8])
      ) d2x_delay (
        .clk (clk),
        .rst (rst),
        .up  (d__x_intfs[i]),
        .dn  (d__x_del[i])
      );
    end
  endgenerate

  generate
    for( i = 0; i < p_num_pipes; i++ ) begin: X2W_DELAY
      X__WDelay #(
        .p_seq_num_bits   (p_seq_num_bits),
        .p_phys_addr_bits (p_phys_addr_bits),
        .p_bp_interval    (p_sim_x2w_bp[i*8 +: 8])
      ) x2w_delay (
        .clk (clk),
        .rst (rst),
        .up  (x__w_intfs[i]),
        .dn  (x__w_del[i])
      );
    end
  endgenerate

`else

  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin: F2D_PASSTHRU
      assign f__d_del[i].inst            = f__d_intfs[i].inst;
      assign f__d_del[i].pc              = f__d_intfs[i].pc;
      assign f__d_del[i].val             = f__d_intfs[i].val;
      assign f__d_del[i].seq_num         = f__d_intfs[i].seq_num;
      assign f__d_del[i].inst_status     = f__d_intfs[i].inst_status;
      assign f__d_del[i].predicted_taken = f__d_intfs[i].predicted_taken;
      assign f__d_intfs[i].rdy           = f__d_del[i].rdy;
    end
  endgenerate

  generate
    for( i = 0; i < p_num_pipes; i++ ) begin: D2X_PASSTHRU
      assign d__x_del[i].pc              = d__x_intfs[i].pc;
      assign d__x_del[i].op1             = d__x_intfs[i].op1;
      assign d__x_del[i].op2             = d__x_intfs[i].op2;
      assign d__x_del[i].waddr           = d__x_intfs[i].waddr;
      assign d__x_del[i].uop             = d__x_intfs[i].uop;
      assign d__x_del[i].val             = d__x_intfs[i].val;
      assign d__x_del[i].seq_num         = d__x_intfs[i].seq_num;
      assign d__x_del[i].preg            = d__x_intfs[i].preg;
      assign d__x_del[i].ppreg           = d__x_intfs[i].ppreg;
      assign d__x_del[i].op3             = d__x_intfs[i].op3;
      assign d__x_del[i].predicted_taken = d__x_intfs[i].predicted_taken;
      assign d__x_intfs[i].rdy           = d__x_del[i].rdy;
    end
  endgenerate

  generate
    for( i = 0; i < p_num_pipes; i++ ) begin: X2W_PASSTHRU
      assign x__w_del[i].pc      = x__w_intfs[i].pc;
      assign x__w_del[i].waddr   = x__w_intfs[i].waddr;
      assign x__w_del[i].wdata   = x__w_intfs[i].wdata;
      assign x__w_del[i].wen     = x__w_intfs[i].wen;
      assign x__w_del[i].val     = x__w_intfs[i].val;
      assign x__w_del[i].seq_num = x__w_intfs[i].seq_num;
      assign x__w_del[i].preg    = x__w_intfs[i].preg;
      assign x__w_del[i].ppreg   = x__w_intfs[i].ppreg;
      assign x__w_intfs[i].rdy   = x__w_del[i].rdy;
    end
  endgenerate

`endif

  //----------------------------------------------------------------------
  // Units
  //----------------------------------------------------------------------

  localparam p_alu_subset = OP_ADD_VEC  |
                            OP_SUB_VEC  |
                            OP_AND_VEC  |
                            OP_OR_VEC   |
                            OP_XOR_VEC  |
                            OP_SLT_VEC  |
                            OP_SLTU_VEC |
                            OP_SRA_VEC  |
                            OP_SRL_VEC  |
                            OP_SLL_VEC  |
                            OP_LUI_VEC  |
                            OP_AUIPC_VEC;

  localparam p_m_subset   = OP_MUL_VEC    |
                            OP_MULH_VEC   |
                            OP_MULHU_VEC  |
                            OP_MULHSU_VEC |
                            OP_DIV_VEC    |
                            OP_DIVU_VEC   |
                            OP_REM_VEC    |
                            OP_REMU_VEC;

  localparam p_mem_subset = OP_LB_VEC  |
                            OP_LH_VEC  |
                            OP_LW_VEC  |
                            OP_LBU_VEC |
                            OP_LHU_VEC |
                            OP_SB_VEC  |
                            OP_SH_VEC  |
                            OP_SW_VEC;

  localparam p_ctrl_subset = OP_JAL_VEC  |
                             OP_JALR_VEC |
                             OP_BEQ_VEC  |
                             OP_BNE_VEC  |
                             OP_BLT_VEC  |
                             OP_BGE_VEC  |
                             OP_BLTU_VEC |
                             OP_BGEU_VEC;

  // Pipe index offsets for MEM and CTRL units
  localparam p_mem_pipe_idx  = p_num_alus + p_num_muls;
  localparam p_ctrl_pipe_idx = p_num_alus + p_num_muls + 1;

  // Build pipe subsets array from parameterized counts
  function automatic rv_op_vec [p_num_pipes-1:0] gen_pipe_subsets;
    for ( int i = 0; i < p_num_alus; i++ )
      gen_pipe_subsets[i] = p_alu_subset;
    for ( int i = 0; i < p_num_muls; i++ )
      gen_pipe_subsets[p_num_alus + i] = p_m_subset;
    gen_pipe_subsets[p_mem_pipe_idx] = p_mem_subset;
    gen_pipe_subsets[p_ctrl_pipe_idx] = p_ctrl_subset;
  endfunction

  localparam rv_op_vec [p_num_pipes-1:0] c_pipe_subsets = gen_pipe_subsets();

  FetchUnit #(
    .p_reclaim_width      (p_reclaim_width),
    .p_seq_num_bits       (p_seq_num_bits),
    .p_num_phys_regs      (p_num_phys_regs),
    .p_max_in_flight      (p_max_in_flight),
    .p_num_fe_lanes       (p_num_fe_lanes),
    .p_num_be_lanes       (p_num_be_lanes),
    .p_enable_branch_pred (p_enable_branch_pred),
    .p_btb_entries        (p_btb_entries),
    .p_btb_ways           (p_btb_ways)
  ) FU (
    .mem       (inst_mem),
    .D         (f__d_intfs),
    .commit    (commit_notif),
    .ctrl_flow (ctrl_flow_gnt_notif),
    .*
  );

  DecodeIssueUnit #(
    .p_num_pipes          (p_num_pipes),
    .p_seq_num_bits       (p_seq_num_bits),
    .p_num_phys_regs      (p_num_phys_regs),
    .p_num_fe_lanes       (p_num_fe_lanes),
    .p_num_be_lanes       (p_num_be_lanes),
    .p_iq_depth           (p_iq_depth),
    .p_pipe_subsets       (c_pipe_subsets),
    .p_pipe_bypass        (p_pipe_bypass),
    .p_ctrl_subset        (p_ctrl_subset),
    .p_mem_subset         (p_mem_subset),
    .p_all_iq_in_order    (p_all_iq_in_order),
    .p_f_intf_fifo_depth  (p_f_intf_fifo_depth)
  ) DIU (
    .F             (f__d_del),
    .Ex            (d__x_intfs),
    .complete      (complete_notif),
    .ctrl_flow_pub (ctrl_flow_arb_notif[0]),
    .ctrl_flow_sub (ctrl_flow_gnt_excl_notif),
    .commit        (commit_notif),
    .*
  );

`ifndef SYNTHESIS
  string alu_trace    [p_num_alus];
  string alu_header   [p_num_alus];
  string mul_trace    [p_num_muls];
  string mul_header   [p_num_muls];
`endif

  generate
    for( i = 0; i < p_num_alus; i++ ) begin: ALU_XU_GEN
      ALU #(
        .p_d_intf_fifo_depth (p_alu_d_intf_fifo_depth)
      ) ALU_XU (
        .D (d__x_del[i]),
        .W (x__w_intfs[i]),
        .*
      );
      `ifndef SYNTHESIS
      always_comb begin
        alu_trace[i]  = `ifdef RTLSIM ALU_XU.trace(0)        `else ALU_XU.tr `endif;
        alu_header[i] = `ifdef RTLSIM ALU_XU.trace_header(0) `else ALU_XU.th `endif;
      end
      `endif
    end
  endgenerate

  generate
    for( i = 0; i < p_num_muls; i++ ) begin: MUL_XU_GEN
      if( p_muldivrem_sel == 0 ) begin: ITER
        IterativeMulDivRem #(
          .p_d_intf_fifo_depth (p_mul_d_intf_fifo_depth)
        ) MUL_DIV_REM_XU (
          .D (d__x_del[p_num_alus + i]),
          .W (x__w_intfs[p_num_alus + i]),
          .*
        );
        `ifndef SYNTHESIS
        always_comb begin
          mul_trace[i]  = `ifdef RTLSIM MUL_DIV_REM_XU.trace(0)        `else MUL_DIV_REM_XU.tr `endif;
          mul_header[i] = `ifdef RTLSIM MUL_DIV_REM_XU.trace_header(0) `else MUL_DIV_REM_XU.th `endif;
        end
        `endif
      end else if( p_muldivrem_sel == 1 ) begin: HYBRID
        SingleCycleMulIterativeDivRem #(
          .p_d_intf_fifo_depth (p_mul_d_intf_fifo_depth)
        ) MUL_DIV_REM_XU (
          .D (d__x_del[p_num_alus + i]),
          .W (x__w_intfs[p_num_alus + i]),
          .*
        );
        `ifndef SYNTHESIS
        always_comb begin
          mul_trace[i]  = `ifdef RTLSIM MUL_DIV_REM_XU.trace(0)        `else MUL_DIV_REM_XU.tr `endif;
          mul_header[i] = `ifdef RTLSIM MUL_DIV_REM_XU.trace_header(0) `else MUL_DIV_REM_XU.th `endif;
        end
        `endif
      end else begin: SCYCLE
        SingleCycleMulDivRem #(
          .p_d_intf_fifo_depth (p_mul_d_intf_fifo_depth)
        ) MUL_DIV_REM_XU (
          .D (d__x_del[p_num_alus + i]),
          .W (x__w_intfs[p_num_alus + i]),
          .*
        );
        `ifndef SYNTHESIS
        always_comb begin
          mul_trace[i]  = `ifdef RTLSIM MUL_DIV_REM_XU.trace(0)        `else MUL_DIV_REM_XU.tr `endif;
          mul_header[i] = `ifdef RTLSIM MUL_DIV_REM_XU.trace_header(0) `else MUL_DIV_REM_XU.th `endif;
        end
        `endif
      end
    end
  endgenerate

  LoadStoreUnit #(
    .p_opaq_bits         (p_opaq_bits),
    .p_num_in_flight     (p_max_in_flight),
    .p_d_intf_fifo_depth (p_mem_d_intf_fifo_depth)
  ) MEM_XU (
    .D   (d__x_del[p_mem_pipe_idx]),
    .W   (x__w_intfs[p_mem_pipe_idx]),
    .mem (data_mem),
    .*
  );

  ControlFlowUnit #(
    .p_d_intf_fifo_depth (p_ctrl_d_intf_fifo_depth)
  ) CTRL_XU (
    .D         (d__x_del[p_ctrl_pipe_idx]),
    .W         (x__w_intfs[p_ctrl_pipe_idx]),
    .ctrl_flow (ctrl_flow_arb_notif[1]),
    .*
  );

  WritebackCommitUnit #(
    .p_num_pipes          (p_num_pipes),
    .p_num_be_lanes       (p_num_be_lanes),
    .p_seq_num_bits       (p_seq_num_bits),
    .p_phys_addr_bits     (p_phys_addr_bits),
    .p_x_intf_fifo_depth  (p_x_intf_fifo_depth)
  ) WCU (
    .Ex       (x__w_del),
    .complete (complete_notif),
    .commit   (commit_notif),
    .*
  );

  CtrlFlowUnit #(
    .p_num_arb       (2),
    .p_diu_idx       (0),
    .p_num_be_lanes  (p_num_be_lanes),
    .p_seq_num_bits  (p_seq_num_bits),
    .p_num_phys_regs (p_num_phys_regs)
  ) SU (
    .arb      (ctrl_flow_arb_notif),
    .gnt      (ctrl_flow_gnt_notif),
    .gnt_excl (ctrl_flow_gnt_excl_notif),
    .commit   (commit_notif),
    .*
  );

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS
  function string trace( int trace_level );
    trace = "";
    trace = {trace, FU.trace( trace_level )};
    trace = {trace, " | "};
    trace = {trace, DIU.trace( trace_level )};
    trace = {trace, " | "};
    for( int i = 0; i < p_num_alus; i++ ) begin
      if( i != 0 ) trace = {trace, ";"};
      trace = {trace, alu_trace[i]};
    end
    trace = {trace, " | "};
    for( int i = 0; i < p_num_muls; i++ ) begin
      if( i != 0 ) trace = {trace, ";"};
      trace = {trace, mul_trace[i]};
    end
    trace = {trace, " | "};
    trace = {trace, MEM_XU.trace( trace_level )};
    trace = {trace, " | "};
    trace = {trace, CTRL_XU.trace( trace_level )};
    trace = {trace, " | "};
    trace = {trace, WCU.trace( trace_level )};
  endfunction

  `TRACE_HEADER_PAD_FN

  function string trace_header( int trace_level );
    int alu_grp_w;
    int mul_grp_w;
    alu_grp_w = (p_num_alus > 0) ?
                  p_num_alus * alu_header[0].len() + (p_num_alus - 1) : 0;
    mul_grp_w = (p_num_muls > 0) ?
                  p_num_muls * mul_header[0].len() + (p_num_muls - 1) : 0;
    trace_header = "";
    trace_header = {trace_header, FU.trace_header( trace_level )};
    trace_header = {trace_header, " | "};
    trace_header = {trace_header, DIU.trace_header( trace_level )};
    trace_header = {trace_header, " | "};
    trace_header = {trace_header, th_pad( "AL", alu_grp_w )};
    trace_header = {trace_header, " | "};
    trace_header = {trace_header, th_pad( "ML", mul_grp_w )};
    trace_header = {trace_header, " | "};
    trace_header = {trace_header, MEM_XU.trace_header( trace_level )};
    trace_header = {trace_header, " | "};
    trace_header = {trace_header, CTRL_XU.trace_header( trace_level )};
    trace_header = {trace_header, " | "};
    trace_header = {trace_header, WCU.trace_header( trace_level )};
  endfunction
`endif

endmodule

`endif // HW_TOP_ZEPPELIN_V
