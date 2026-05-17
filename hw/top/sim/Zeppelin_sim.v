//========================================================================
// Zeppelin_sim.v
//========================================================================
// A module for simulating Zeppelin

`ifdef RTLSIM
  `define USE_ASIC_WRAP
`elsif FFGLSIM
  `define USE_ASIC_WRAP
`elsif BAGLSIM
  `define USE_ASIC_WRAP
`endif

`ifndef FFGLSIM
`ifndef BAGLSIM
  `define DO_DUT_TRACE
`endif
`endif

`include "asm/assemble.v"
`ifndef USE_ASIC_WRAP
`include "hw/top/Zeppelin.v"
`endif
`include "hw/top/sim/utils/SimUtils.v"
`include "intf/MemIntf.v"
`include "intf/InstTraceNotif.v"
`include "test/fl/MemIntfTestServer.v"
`include "hw/top/Zeppelin_defaults.vh"

import "DPI-C" context function void load_elf ( string elf_file );

module Zeppelin_sim;

  // Define default simulation parameters
  localparam p_opaq_bits               = `P_OPAQ_BITS;
  localparam p_seq_num_bits            = `P_SEQ_NUM_BITS;
  localparam p_num_phys_regs           = `P_NUM_PHYS_REGS;
  localparam p_num_fe_lanes            = `P_NUM_FE_LANES;
  localparam p_num_be_lanes            = `P_NUM_BE_LANES;
  localparam p_iq_depth                = `P_IQ_DEPTH;
  localparam p_reclaim_width           = `P_RECLAIM_WIDTH;
  localparam p_max_in_flight           = `P_MAX_IN_FLIGHT;
  localparam p_f_intf_fifo_depth       = `P_F_INTF_FIFO_DEPTH;
  localparam p_x_intf_fifo_depth       = `P_X_INTF_FIFO_DEPTH;
  localparam p_alu_d_intf_fifo_depth   = `P_ALU_D_INTF_FIFO_DEPTH;
  localparam p_mul_d_intf_fifo_depth   = `P_MUL_D_INTF_FIFO_DEPTH;
  localparam p_mem_d_intf_fifo_depth   = `P_MEM_D_INTF_FIFO_DEPTH;
  localparam p_ctrl_d_intf_fifo_depth  = `P_CTRL_D_INTF_FIFO_DEPTH;
  localparam p_num_alus                = `P_NUM_ALUS;
  localparam p_num_muls                = `P_NUM_MULS;
  localparam p_all_iq_in_order         = `P_ALL_IQ_IN_ORDER;
  localparam p_pipe_bypass             = `P_PIPE_BYPASS;
  localparam p_muldivrem_sel           = `P_MULDIVREM_SEL;
  localparam p_enable_branch_pred      = `P_ENABLE_BRANCH_PRED;
  localparam p_btb_entries             = `P_BTB_ENTRIES;
  localparam p_btb_ways                = `P_BTB_WAYS;
  localparam p_num_pipes               = p_num_alus + p_num_muls + 2;
  localparam [p_num_fe_lanes*8-1:0] p_sim_f2d_bp = '0;
  localparam [p_num_pipes*8-1:0]    p_sim_d2x_bp = '0;
  localparam [p_num_pipes*8-1:0]    p_sim_x2w_bp = '0;
  
  //----------------------------------------------------------------------
  // Setup
  //----------------------------------------------------------------------

  logic clk;
  logic rst;

  SimUtils t( .* );

  `MEM_REQ_DEFINE ( p_opaq_bits );
  `MEM_RESP_DEFINE( p_opaq_bits );

  `MEM_REQ_DEFINE_SS ( p_opaq_bits, p_num_fe_lanes );
  `MEM_RESP_DEFINE_SS( p_opaq_bits, p_num_fe_lanes );

  //----------------------------------------------------------------------
  // Instantiate processor
  //----------------------------------------------------------------------

  MemIntf #(
    .p_opaq_bits (p_opaq_bits),
    .p_num_words (p_num_fe_lanes)
  ) imem_intf();

  MemIntf #(
    .p_opaq_bits (p_opaq_bits)
  ) dmem_intf();

  InstTraceNotif #(
    .p_seq_num_bits (p_seq_num_bits)
  ) inst_trace_notif [p_num_be_lanes]();

  logic [31:0]               inst_trace_notif_pc      [p_num_be_lanes];
  logic  [4:0]               inst_trace_notif_waddr   [p_num_be_lanes];
  logic [31:0]               inst_trace_notif_wdata   [p_num_be_lanes];
  logic                      inst_trace_notif_wen     [p_num_be_lanes];
  logic                      inst_trace_notif_val     [p_num_be_lanes];
  logic [p_seq_num_bits-1:0] inst_trace_notif_seq_num [p_num_be_lanes];

`ifdef USE_ASIC_WRAP

  // Derived message bit widths (must match ZeppelinASICWrap)

  localparam p_imem_data_bits = p_num_fe_lanes * 32;
  localparam p_imem_strb_bits = p_num_fe_lanes * 4;
  localparam p_imem_msg_bits  = 1 + p_opaq_bits + 32
                              + p_imem_strb_bits + p_imem_data_bits;
  localparam p_dmem_data_bits = 32;
  localparam p_dmem_strb_bits = 4;
  localparam p_dmem_msg_bits  = 1 + p_opaq_bits + 32
                              + p_dmem_strb_bits + p_dmem_data_bits;

  //--------------------------------------------------------------------
  // Dmem wires for ASICWrap interface
  //--------------------------------------------------------------------

  logic                       dmem_req_val;
  logic                       dmem_req_rdy;
  logic [p_dmem_msg_bits-1:0] dmem_req_msg;
  logic                       dmem_resp_val;
  logic                       dmem_resp_rdy;
  logic [p_dmem_msg_bits-1:0] dmem_resp_msg;

  assign dmem_intf.req_val  = dmem_req_val;
  assign dmem_req_rdy       = dmem_intf.req_rdy;
  assign dmem_intf.req_msg  = dmem_req_msg;
  assign dmem_resp_val      = dmem_intf.resp_val;
  assign dmem_intf.resp_rdy = dmem_resp_rdy;
  assign dmem_resp_msg      = dmem_intf.resp_msg;

  //--------------------------------------------------------------------
  // DUT instantiation
  //--------------------------------------------------------------------

  logic [p_num_be_lanes*32-1:0]             dut_trace_pc;
  logic [p_num_be_lanes*5-1:0]              dut_trace_waddr;
  logic [p_num_be_lanes*32-1:0]             dut_trace_wdata;
  logic [p_num_be_lanes-1:0]                dut_trace_wen;
  logic [p_num_be_lanes-1:0]                dut_trace_val;
  logic [p_num_be_lanes*p_seq_num_bits-1:0] dut_trace_seq_num;

  ZeppelinASICWrap dut (
    .clk            (clk),
    .rst            (rst),
    .imem_req_val   (imem_intf.req_val),
    .imem_req_rdy   (imem_intf.req_rdy),
    .imem_req_msg   (imem_intf.req_msg),
    .imem_resp_val  (imem_intf.resp_val),
    .imem_resp_rdy  (imem_intf.resp_rdy),
    .imem_resp_msg  (imem_intf.resp_msg),
    .dmem_req_val   (dmem_req_val),
    .dmem_req_rdy   (dmem_req_rdy),
    .dmem_req_msg   (dmem_req_msg),
    .dmem_resp_val  (dmem_resp_val),
    .dmem_resp_rdy  (dmem_resp_rdy),
    .dmem_resp_msg  (dmem_resp_msg),
    .trace_pc       (dut_trace_pc),
    .trace_waddr    (dut_trace_waddr),
    .trace_wdata    (dut_trace_wdata),
    .trace_wen      (dut_trace_wen),
    .trace_val      (dut_trace_val),
    .trace_seq_num  (dut_trace_seq_num)
  );

`else

  Zeppelin #(
    .p_opaq_bits              (p_opaq_bits),
    .p_seq_num_bits           (p_seq_num_bits),
    .p_num_phys_regs          (p_num_phys_regs),
    .p_num_fe_lanes           (p_num_fe_lanes),
    .p_num_be_lanes           (p_num_be_lanes),
    .p_iq_depth               (p_iq_depth),
    .p_reclaim_width          (p_reclaim_width),
    .p_max_in_flight          (p_max_in_flight),
    .p_f_intf_fifo_depth      (p_f_intf_fifo_depth),
    .p_x_intf_fifo_depth      (p_x_intf_fifo_depth),
    .p_alu_d_intf_fifo_depth  (p_alu_d_intf_fifo_depth),
    .p_mul_d_intf_fifo_depth  (p_mul_d_intf_fifo_depth),
    .p_mem_d_intf_fifo_depth  (p_mem_d_intf_fifo_depth),
    .p_ctrl_d_intf_fifo_depth (p_ctrl_d_intf_fifo_depth),
    .p_num_alus               (p_num_alus),
    .p_num_muls               (p_num_muls),
    .p_all_iq_in_order        (p_all_iq_in_order),
    .p_pipe_bypass            (p_pipe_bypass),
    .p_muldivrem_sel          (p_muldivrem_sel),
    .p_enable_branch_pred     (p_enable_branch_pred),
    .p_btb_entries            (p_btb_entries),
    .p_btb_ways               (p_btb_ways),
    .p_sim_f2d_bp             (p_sim_f2d_bp),
    .p_sim_d2x_bp             (p_sim_d2x_bp),
    .p_sim_x2w_bp             (p_sim_x2w_bp)
  ) dut (
    .inst_mem   (imem_intf),
    .data_mem   (dmem_intf),
    .inst_trace (inst_trace_notif),
    .*
  );

`endif

  //----------------------------------------------------------------------
  // Instruction Tracing
  //----------------------------------------------------------------------

  genvar i;
  generate
    for( i = 0; i < p_num_be_lanes; i++ ) begin : TRACE_UNPACK
      assign inst_trace_notif_pc[i]      = `ifdef USE_ASIC_WRAP dut_trace_pc   [i*32 +: 32] `else inst_trace_notif[i].pc    `endif;
      assign inst_trace_notif_waddr[i]   = `ifdef USE_ASIC_WRAP dut_trace_waddr[i*5 +: 5]   `else inst_trace_notif[i].waddr `endif;
      assign inst_trace_notif_wdata[i]   = `ifdef USE_ASIC_WRAP dut_trace_wdata[i*32 +: 32] `else inst_trace_notif[i].wdata `endif;
      assign inst_trace_notif_wen[i]     = `ifdef USE_ASIC_WRAP dut_trace_wen  [i]          `else inst_trace_notif[i].wen   `endif;
      assign inst_trace_notif_val[i]     = `ifdef USE_ASIC_WRAP dut_trace_val  [i]          `else inst_trace_notif[i].val   `endif;
      assign inst_trace_notif_seq_num[i] = 
      `ifdef USE_ASIC_WRAP dut_trace_seq_num[i*p_seq_num_bits +: p_seq_num_bits]; 
      `else inst_trace_notif[i].seq_num;
      `endif
    end
  endgenerate

  always @( posedge clk ) begin
    `ifndef BAGLSIM
    #1;
    `else
    #(`CYCLE_TIME-`OUTPUT_DELAY);
    `endif
    begin
      int num_committed;
      num_committed = 0;
      for( int j = 0; j < p_num_be_lanes; j++ ) begin
        if( inst_trace_notif_val[j] ) begin
          num_committed = num_committed + 1;
          t.inst_trace(
            inst_trace_notif_pc[j],
            inst_trace_notif_waddr[j],
            inst_trace_notif_wdata[j],
            inst_trace_notif_wen[j]
          );
        end
      end
      if( num_committed > 0 ) begin
        t.commit_notify( num_committed );
        fl_dmem.notify_commit( num_committed );
      end
    end
  end

  //----------------------------------------------------------------------
  // FL Memory
  //----------------------------------------------------------------------

  MemIntfTestServer #(
    .t_req_msg         (`MEM_REQ_SS ( p_opaq_bits, p_num_fe_lanes )),
    .t_resp_msg        (`MEM_RESP_SS( p_opaq_bits, p_num_fe_lanes )),
    .p_send_intv_delay ( 1 ),
    .p_recv_intv_delay ( 1 ),
    .p_opaq_bits       (p_opaq_bits),
    .p_num_words       (p_num_fe_lanes)
  ) fl_imem (
    .dut (imem_intf),
    .*
  );

  MemIntfTestServer #(
    .t_req_msg         (`MEM_REQ ( p_opaq_bits )),
    .t_resp_msg        (`MEM_RESP( p_opaq_bits )),
    .p_send_intv_delay ( 1 ),
    .p_recv_intv_delay ( 1 ),
    .p_opaq_bits       (p_opaq_bits)
  ) fl_dmem (
    .dut (dmem_intf),
    .*
  );

  function void init_mem(
    input bit [31:0] addr,
    input bit [31:0] data
  );

    // Write both with same data, not optimal but I don't want
    // to change the C code lol
    fl_imem.init_mem( addr, data );
    fl_dmem.init_mem( addr, data );
  endfunction

  export "DPI-C" function init_mem;

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

  string trace;

  function string trace_header();
    trace_header = "";
    // trace_header = {trace_header, fl_imem.trace_header( t.trace_level )};
    // trace_header = {trace_header, " || "};
    // trace_header = {trace_header, fl_dmem.trace_header( t.trace_level )};
    // trace_header = {trace_header, " || "};
    `ifdef DO_DUT_TRACE
    trace_header = {trace_header, dut.trace_header( t.trace_level )};
    `endif
  endfunction

  initial begin
    #0;
    t.trace_header = trace_header();
  end

  // verilator lint_off BLKSEQ
  always @( posedge clk ) begin
    `ifndef BAGLSIM
    #(`CYCLE_TIME-1);
    `else
    #(`CYCLE_TIME-`OUTPUT_DELAY);
    `endif
    trace = "";

    // trace = {trace, fl_imem.trace( t.trace_level )};
    // trace = {trace, " || "};
    // trace = {trace, fl_dmem.trace( t.trace_level )};
    // trace = {trace, " || "};
    `ifdef DO_DUT_TRACE
    trace = {trace, dut.trace( t.trace_level )};
    `endif

    t.trace( trace );
  end
  // verilator lint_on BLKSEQ

  //----------------------------------------------------------------------
  // SAIF Dumping
  //----------------------------------------------------------------------

`ifdef VTB_DUMP_SAIF
  string saif_file;
`endif

  //----------------------------------------------------------------------
  // Run the simulation
  //----------------------------------------------------------------------

  initial begin
`ifdef VTB_DUMP_SAIF
    if (!$value$plusargs("saif=%s", saif_file)) saif_file = "dump.saif";
    $set_gate_level_monitoring("on");
    $set_toggle_region(dut);
    $display("SAIF dumping enabled: dumping to %s", saif_file);
`endif
    t.sim_begin();
    load_elf( t.elf_file );
  end

`ifdef VTB_DUMP_SAIF
  final begin
    $toggle_report(saif_file, 1e-12, dut);
    $display("SAIF dumping complete");
  end
`endif

endmodule
