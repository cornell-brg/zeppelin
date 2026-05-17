//========================================================================
// FetchUnit.v
//========================================================================
// A FIFO-less fetch unit for fetching instructions with ctrl_flowing and
// support for superscalar backend. Uses a single wide memory interface;
// the response data is unpacked into p_num_fe_lanes items. Memory
// responses flow directly to the D interface with no buffering.

`ifndef HW_FETCH_FETCHUNIT_V
`define HW_FETCH_FETCHUNIT_V

`include "hw/fetch/SeqNumGen.v"
`include "hw/fetch/FetchSquashTracker.v"
`include "hw/fetch/FetchAddrGen.v"
`include "hw/fetch/BranchPredictor.v"
`include "hw/common/Fifo.v"
`include "hw/util/TraceHeader.v"
`include "intf/F__DIntf.v"
`include "intf/MemIntf.v"
`include "intf/CommitNotif.v"
`include "intf/ControlFlowNotif.v"

module FetchUnit
#(
  parameter p_reclaim_width      = 2,
  parameter p_seq_num_bits       = 5,
  parameter p_num_phys_regs      = 36,
  parameter p_max_in_flight      = 16,
  parameter p_num_fe_lanes       = 2,
  parameter p_num_be_lanes       = 2,
  parameter p_enable_branch_pred = 0,
  parameter p_btb_entries        = 1,
  parameter p_btb_ways           = p_btb_entries
)
(
  input  logic    clk,
  input  logic    rst,

  //----------------------------------------------------------------------
  // Memory Interface (single wide port)
  //----------------------------------------------------------------------

  MemIntf.client mem,

  //----------------------------------------------------------------------
  // F <-> D Interface
  //----------------------------------------------------------------------

  F__DIntf.F_intf D [p_num_fe_lanes],

  //----------------------------------------------------------------------
  // Commit Interface
  //----------------------------------------------------------------------

  CommitNotif.sub commit [p_num_be_lanes],

  //----------------------------------------------------------------------
  // Control Flow Interface
  //----------------------------------------------------------------------

  ControlFlowNotif.sub ctrl_flow
);

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Local Parameters
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  localparam       p_rst_addr          = 32'h200;

  localparam [1:0] INST_STATUS_INVALID = 2'b00,
                   INST_STATUS_READY   = 2'b01;

  localparam       p_flight_bits       = $clog2(p_max_in_flight) + 1 > $clog2(p_num_fe_lanes) + 1
                                         ? $clog2(p_max_in_flight) + 1
                                         : $clog2(p_num_fe_lanes) + 1;
  localparam       p_lane_idx_bits     = p_num_fe_lanes > 1 ?
                                          $clog2(p_num_fe_lanes) : 1;
  localparam       p_pred_fifo_depth   = 2**$clog2(p_max_in_flight); // Round up to power of 2 (Fifo requirement)

  logic                       bp_redirect_val;
  logic                [31:0] bp_redirect_target;
  logic                       bp_resp_pred_taken;
  logic [p_lane_idx_bits-1:0] bp_resp_branch_lane;

  genvar i;

  //----------------------------------------------------------------------
  // Transfer handshake signals
  //----------------------------------------------------------------------

  logic memreq_xfer;
  logic D_xfer_all;
  logic D_xfer [p_num_fe_lanes];
  logic D_rdy_all;

  // Local copy of D[i].rdy — Verilator cannot index an interface array
  // with a non-constant variable inside always_comb.
  logic D_rdy [p_num_fe_lanes];

  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin: D_RDY_CONNECT
      assign D_rdy[i] = D[i].rdy;
    end
  endgenerate

  logic ctrl_flow_redirect;
  assign ctrl_flow_redirect = ctrl_flow.redirect_val;

  //----------------------------------------------------------------------
  // CtrlFlow Tracker
  //----------------------------------------------------------------------

  logic [p_flight_bits-1:0]   num_in_flight;
  logic [p_flight_bits-1:0]   num_to_squash;
  logic                       should_drop;
  logic                       needs_ctrl_flow_restart;
  logic [p_lane_idx_bits-1:0] ctrl_flow_restart_offset;
  logic [p_lane_idx_bits-1:0] ctrl_flow_lane_offset;

  FetchSquashTracker #(
    .p_max_in_flight (p_max_in_flight),
    .p_num_fe_lanes  (p_num_fe_lanes)
  ) redirect_tracker (
    .clk                      (clk),
    .rst                      (rst),
    .ctrl_flow                (ctrl_flow),
    .ctrl_flow_lane_offset    (ctrl_flow_lane_offset),
    .memreq_xfer              (memreq_xfer),
    .D_xfer_all               (D_xfer_all),
    .mem_resp_val             (mem.resp_val),
    .num_in_flight            (num_in_flight),
    .num_to_squash            (num_to_squash),
    .should_drop              (should_drop),
    .needs_ctrl_flow_restart  (needs_ctrl_flow_restart),
    .ctrl_flow_restart_offset (ctrl_flow_restart_offset)
  );

  //----------------------------------------------------------------------
  // Branch Predictor
  //----------------------------------------------------------------------

  logic [31:0] mem_req_addr;
  logic        bp_pred_taken;
  logic [p_lane_idx_bits-1:0] bp_branch_lane;

  generate
    if ( p_enable_branch_pred ) begin : gen_bp

      BranchPredictor #(
        .p_btb_entries  (p_btb_entries),
        .p_btb_ways     (p_btb_ways),
        .p_num_fe_lanes (p_num_fe_lanes)
      ) bp (
        .clk             (clk),
        .rst             (rst),
        .req_pc          (mem_req_addr),
        .memreq_xfer     (memreq_xfer),
        .redirect_val    (bp_redirect_val),
        .redirect_target (bp_redirect_target),
        .pred_taken      (bp_pred_taken),
        .branch_lane     (bp_branch_lane),
        .ctrl_flow       (ctrl_flow)
      );

      // Prediction FIFO — tracks whether each in-flight fetch request was
      // redirected and which lane the branch occupies. Pushed on memreq_xfer,
      // popped on resp_xfer. No ctrl_flow clear — stale entries drain naturally.

      localparam p_pred_fifo_bits = 1 + p_lane_idx_bits;
      logic [p_pred_fifo_bits-1:0] pred_fifo_rdata;

      Fifo #(
        .p_entry_bits (p_pred_fifo_bits),
        .p_depth      (p_pred_fifo_depth)
      ) pred_fifo (
        .clk   (clk),
        .rst   (rst),
        .clear (1'b0),
        .push  (memreq_xfer),
        .pop   (mem.resp_val & mem.resp_rdy),
        .wdata ({bp_pred_taken & !ctrl_flow_redirect, bp_branch_lane}),
        .rdata (pred_fifo_rdata),
        .empty (),
        .full  ()
      );

      assign bp_resp_pred_taken  = pred_fifo_rdata[p_lane_idx_bits];
      assign bp_resp_branch_lane = pred_fifo_rdata[p_lane_idx_bits-1:0];

    end else begin : gen_no_bp

      assign bp_pred_taken       = 1'b0;
      assign bp_branch_lane      = '0;
      assign bp_resp_pred_taken  = 1'b0;
      assign bp_resp_branch_lane = '0;
      assign bp_redirect_val     = 1'b0;
      assign bp_redirect_target  = 32'b0;

    end
  endgenerate

  //----------------------------------------------------------------------
  // Address Generator
  //----------------------------------------------------------------------

  FetchAddrGen #(
    .p_num_fe_lanes       (p_num_fe_lanes),
    .p_max_in_flight      (p_max_in_flight),
    .p_rst_addr           (p_rst_addr),
    .p_enable_branch_pred (p_enable_branch_pred)
  ) addr_gen (
    .clk                   (clk),
    .rst                   (rst),
    .ctrl_flow             (ctrl_flow),
    .memreq_rdy            (mem.req_rdy),
    .num_in_flight         (num_in_flight),
    .num_to_squash         (num_to_squash),
    .bp_redirect_val       (bp_redirect_val),
    .bp_redirect_target    (bp_redirect_target),
    .mem_req_val           (mem.req_val),
    .mem_req_addr          (mem_req_addr),
    .memreq_xfer           (memreq_xfer),
    .ctrl_flow_lane_offset (ctrl_flow_lane_offset)
  );

  assign mem.req_msg.op     = MEM_MSG_READ;
  assign mem.req_msg.opaque = '0;
  assign mem.req_msg.addr   = mem_req_addr;
  assign mem.req_msg.strb   = '0;
  assign mem.req_msg.data   = '0;

  //----------------------------------------------------------------------
  // Response
  //----------------------------------------------------------------------

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Allocation
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  logic [p_seq_num_bits-1:0] alloc_seq_num [p_num_fe_lanes];
  logic                      alloc_try     [p_num_fe_lanes];
  logic                      alloc_rdy     [p_num_fe_lanes];
  logic                      alloc_val     [p_num_fe_lanes];

  SeqNumGen #(
    .p_seq_num_bits  (p_seq_num_bits),
    .p_num_phys_regs (p_num_phys_regs),
    .p_reclaim_width (p_reclaim_width),
    .p_num_fe_lanes  (p_num_fe_lanes),
    .p_num_be_lanes  (p_num_be_lanes)
  ) seq_num_gen (
    .clk           (clk),
    .rst           (rst),
    .alloc_seq_num (alloc_seq_num),
    .alloc_try     (alloc_try),
    .alloc_rdy     (alloc_rdy),
    .alloc_val     (alloc_val),
    .commit        (commit),
    .ctrl_flow     (ctrl_flow)
  );

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Per-lane active/masked signals
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // lane_active: lane carries a valid instruction (normal or restart). Inactive
  // lanes in a non-dropped block and instructions following a predicted-taken
  // branch send bubbles (INST_STATUS_INVALID)

  logic lane_active [p_num_fe_lanes];

  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin: LANE_ACTIVE_GEN
      /* verilator lint_off CMPCONST */
      /* verilator lint_off UNSIGNED */
      if ( p_enable_branch_pred ) begin : gen_lane_active_bp
        assign lane_active[i] = !should_drop &
                                 !(bp_resp_pred_taken &
                                   (p_lane_idx_bits'(unsigned'(i)) > bp_resp_branch_lane)) &
                                 (!needs_ctrl_flow_restart |
                                  (p_lane_idx_bits'(unsigned'(i)) >= ctrl_flow_restart_offset));
      end else begin : gen_lane_active_no_bp
        assign lane_active[i] = !should_drop &
                                 (!needs_ctrl_flow_restart |
                                  (p_lane_idx_bits'(unsigned'(i)) >= ctrl_flow_restart_offset));
      end
      /* verilator lint_on UNSIGNED */
      /* verilator lint_on CMPCONST */
    end
  endgenerate

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Response signals
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  logic alloc_ok [p_num_fe_lanes];
  logic alloc_ok_all;

  always_comb begin
    alloc_ok_all = 1'b1;
    for( int j = 0; j < p_num_fe_lanes; j++ ) begin
      if( lane_active[j] )
        alloc_ok_all &= alloc_ok[j];
    end
  end

  always_comb begin
    D_xfer_all = 1'b1;
    D_rdy_all  = 1'b1;
    for( int j = 0; j < p_num_fe_lanes; j++ ) begin
      D_xfer_all &= D_xfer[j];
      D_rdy_all  &= D_rdy[j];
    end
  end

  // Accept memory responses when dropping stale data or when D is ready
  assign mem.resp_rdy = should_drop | (D_rdy_all & alloc_ok_all);

  // Per-lane response signals and D interface connection
  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin: RESP_LANE
      assign alloc_try[i]     = mem.resp_val & D_rdy_all & lane_active[i];
      assign alloc_val[i]     = alloc_try[i] & alloc_rdy[i];
      assign alloc_ok[i]      = alloc_val[i];
      assign D[i].val         = lane_active[i] ? (mem.resp_val & alloc_ok[i]) :
                                !should_drop   ? mem.resp_val : 1'b0;
      assign D[i].inst        = mem.resp_msg.data[unsigned'(i)*32 +: 32];
      assign D[i].pc          = mem.resp_msg.addr + 32'(unsigned'(i) << 2);
      assign D[i].seq_num     = alloc_seq_num[i];
      assign D[i].inst_status = lane_active[i] ? INST_STATUS_READY
                                               : INST_STATUS_INVALID;
      assign D_xfer[i]        = D[i].val & D_rdy[i];

      if ( p_enable_branch_pred ) begin : gen_d_bp
        assign D[i].predicted_taken = bp_resp_pred_taken &
                                         (p_lane_idx_bits'(unsigned'(i)) == bp_resp_branch_lane);
      end else begin : gen_d_no_bp
        assign D[i].predicted_taken = 1'b0;
      end
    end
  endgenerate

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Unused signals
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  logic [p_seq_num_bits-1:0] unused_ctrl_flow_seq_num;

  always_comb begin
    unused_ctrl_flow_seq_num = ctrl_flow.seq_num;
  end

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS
  function int ceil_div_4( int val );
    return (val / 4) + ((val % 4) > 0 ? 1 : 0);
  endfunction

  function string trace(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    int    seq_w;
    int    req_w;
    int    resp_w;
    int    n;
    int    pad_left;
    string body;
    string pad;
    // Lanes within FU response are `;`-separated (1-char ";").
    seq_w  = p_num_fe_lanes * ceil_div_4(p_seq_num_bits) + (p_num_fe_lanes - 1);
    req_w  = 4;             // lower-4 hex of addr (or centered "(#)" on stall)
    resp_w = 4 + 2 + seq_w; // addr + ": " + lanes (or centered "(#)" on stall)

    if( mem.req_val & !mem.req_rdy ) begin
      pad_left = (req_w - 3) / 2;
      body = "";
      for( n = 0; n < pad_left; n = n + 1 )
        body = {body, " "};
      body = {body, "#"};
    end else if( mem.req_val ) begin
      body = $sformatf("%h", mem.req_msg.addr[15:0]);
    end else begin
      body = "";
    end
    pad = "";
    for( n = body.len(); n < req_w; n = n + 1 )
      pad = {pad, " "};
    trace = {body, pad, ">"};

    if( mem.resp_val ) begin
      if( should_drop ) begin
        pad_left = (resp_w - 3) / 2;
        body = "";
        for( n = 0; n < pad_left; n = n + 1 )
          body = {body, " "};
        body = {body, "S"};
      end else if( !D_rdy_all ) begin
        pad_left = (resp_w - 3) / 2;
        body = "";
        for( n = 0; n < pad_left; n = n + 1 )
          body = {body, " "};
        body = {body, "#"};
      end else begin
        body = $sformatf("%h: ", mem.resp_msg.addr[15:0]);
        for( int i = 0; i < p_num_fe_lanes; i++ ) begin
          if( i != 0 )
            body = {body, ";"};
          if( D_xfer[i] | (lane_active[i] & alloc_val[i]) )
            body = {body, $sformatf("%h", alloc_seq_num[i])};
          else
            body = {body, {(ceil_div_4(p_seq_num_bits)){" "}}};
        end
      end
    end else begin
      body = "";
    end
    pad = "";
    for( n = body.len(); n < resp_w; n = n + 1 )
      pad = {pad, " "};
    trace = {trace, body, pad};
  endfunction

  `TRACE_HEADER_PAD_FN

  function string trace_header(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    int seq_w;
    int req_w;
    int resp_w;
    seq_w  = p_num_fe_lanes * ceil_div_4(p_seq_num_bits) + (p_num_fe_lanes - 1);
    req_w  = 4;
    resp_w = 4 + 2 + seq_w;
    trace_header = {th_pad( "FREQ", req_w ), ">", th_pad( "FREP", resp_w )};
  endfunction
`endif

endmodule

`endif // HW_FETCH_FETCHUNIT_V
