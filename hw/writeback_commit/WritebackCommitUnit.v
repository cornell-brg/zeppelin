//========================================================================
// WritebackCommitUnit.v
//========================================================================
// A writeback unit that reorders messages based on sequence number
// (including physical register specifiers) and allows for multiple
// independent instructions to commit simultaneously

`ifndef HW_WRITEBACK_WRITEBACKCOMMITUNIT_V
`define HW_WRITEBACK_WRITEBACKCOMMITUNIT_V

`include "hw/writeback_commit/SSROB.v"
`include "hw/writeback_commit/WCUFifo.v"
`include "hw/util/TraceHeader.v"
`include "hw/writeback_commit/SSWCUArb.v"
`include "intf/CompleteNotif.v"
`include "intf/CommitNotif.v"
`include "intf/X__WIntf.v"

module WritebackCommitUnit #(
  parameter p_num_pipes         = 1,
  parameter p_num_be_lanes      = 2,
  parameter p_seq_num_bits      = 5,
  parameter p_phys_addr_bits    = 6,
  parameter p_x_intf_fifo_depth = 4
)(
  input  logic clk,
  input  logic rst,

  //----------------------------------------------------------------------
  // X <-> W Interface
  //----------------------------------------------------------------------

  X__WIntf.W_intf Ex [p_num_pipes],

  //----------------------------------------------------------------------
  // Completion Interfaces
  //----------------------------------------------------------------------

  CompleteNotif.pub complete [p_num_be_lanes],

  //----------------------------------------------------------------------
  // Commit Interface
  //----------------------------------------------------------------------

  CommitNotif.pub commit [p_num_be_lanes]
);

  localparam p_rob_depth = 2 ** p_seq_num_bits;

  CommitNotif #(
    .p_seq_num_bits   (p_seq_num_bits),
    .p_phys_addr_bits (p_phys_addr_bits)
  ) local_commit [p_num_be_lanes]();

  //----------------------------------------------------------------------
  // Writeback message struct (used throughout the pipeline)
  //----------------------------------------------------------------------

  typedef struct packed {
    logic                        val;
    logic                 [31:0] pc;
    logic   [p_seq_num_bits-1:0] seq_num;
    logic                  [4:0] waddr;
    logic                 [31:0] wdata;
    logic                        wen;
    logic [p_phys_addr_bits-1:0] preg;
    logic [p_phys_addr_bits-1:0] ppreg;
  } t_wb_msg;

  //----------------------------------------------------------------------
  // Unpack interface signals
  //----------------------------------------------------------------------

  t_wb_msg Ex_msg [p_num_pipes];
  logic    Ex_rdy [p_num_pipes];

  genvar i;
  generate
    for( i = 0; i < p_num_pipes; i = i + 1 ) begin: UNPACK_FROM_INTF
      assign Ex_msg[i].val     = Ex[i].val;
      assign Ex_msg[i].pc      = Ex[i].pc;
      assign Ex_msg[i].seq_num = Ex[i].seq_num;
      assign Ex_msg[i].waddr   = Ex[i].waddr;
      assign Ex_msg[i].wdata   = Ex[i].wdata;
      assign Ex_msg[i].wen     = Ex[i].wen;
      assign Ex_msg[i].preg                   = Ex[i].preg;
      assign Ex_msg[i].ppreg                  = Ex[i].ppreg;
      assign Ex[i].rdy                        = Ex_rdy[i];
    end
  endgenerate

  //----------------------------------------------------------------------
  // Arbiter budget
  //----------------------------------------------------------------------

  logic fifo_full;
  logic fifo_pop;

  logic [p_seq_num_bits:0]         avail_slots_ssrob;
  logic [$clog2(p_num_be_lanes):0] avail_slots_arb;

  assign avail_slots_arb = (fifo_full & !fifo_pop) ? '0 :
                           ($clog2(p_num_be_lanes)+1)'(avail_slots_ssrob > p_num_be_lanes ?
                                                  p_num_be_lanes :
                                                  avail_slots_ssrob);

  //----------------------------------------------------------------------
  // Arbitration and selection
  //----------------------------------------------------------------------
  // SSWCUArb (age-based) handles arbitration + selection muxing internally

  t_wb_msg Ex_msg_sel [p_num_be_lanes];

  SSWCUArb #(
    .t_msg          (t_wb_msg),
    .p_num_pipes    (p_num_pipes),
    .p_num_be_lanes (p_num_be_lanes),
    .p_seq_num_bits (p_seq_num_bits)
  ) ex_arb (
    .clk     (clk),
    .rst     (rst),
    .en      (1'b1),
    .m       (avail_slots_arb),
    .in_msg  (Ex_msg),
    .rdy     (Ex_rdy),
    .sel_msg (Ex_msg_sel),
    .commit  (local_commit)
  );

  //----------------------------------------------------------------------
  // Complete notifications (driven from pre-FIFO arbiter output)
  //----------------------------------------------------------------------

  generate
    for( i = 0; i < p_num_be_lanes; i = i + 1 ) begin: COMPLETE_GEN
      assign complete[i].val     = Ex_msg_sel[i].val;
      assign complete[i].seq_num = Ex_msg_sel[i].seq_num;
      assign complete[i].waddr   = Ex_msg_sel[i].waddr;
      assign complete[i].wdata   = Ex_msg_sel[i].wdata;
      assign complete[i].wen     = ( Ex_msg_sel[i].waddr == '0 ) ? 0 : 
                                     Ex_msg_sel[i].wen;
      assign complete[i].preg    = Ex_msg_sel[i].preg;
    end
  endgenerate

  //----------------------------------------------------------------------
  // Bypass FIFO for X interface
  //----------------------------------------------------------------------

  t_wb_msg                   fifo_in          [p_num_be_lanes];
  logic [p_num_be_lanes-1:0] Ex_val_sel_packed;

  generate
    for( i = 0; i < p_num_be_lanes; i = i + 1 ) begin: FIFO_IN_GEN
      assign Ex_val_sel_packed[i] = Ex_msg_sel[i].val;
      assign fifo_in[i]           = Ex_msg_sel[i];
    end
  endgenerate

  logic fifo_push, fifo_empty;
  assign fifo_push = |Ex_val_sel_packed & (!fifo_full | fifo_pop);
  assign fifo_pop  = !fifo_empty;

  t_wb_msg X_curr [p_num_be_lanes];

  WCUFifo #(
    .p_entry_bits (p_num_be_lanes * $bits(t_wb_msg)),
    .p_depth      (p_x_intf_fifo_depth),
    .p_num_lanes  (p_num_be_lanes)
  ) x_fifo (
    .clk   (clk),
    .rst   (rst),
    .push  (fifo_push),
    .i_msg (fifo_in),
    .full  (fifo_full),
    .pop   (fifo_pop),
    .empty (fifo_empty),
    .o_msg (X_curr)
  );

  //----------------------------------------------------------------------
  // ROB
  //----------------------------------------------------------------------

  t_wb_msg rob_input [p_num_be_lanes], rob_output [p_num_be_lanes];

  logic [p_seq_num_bits-1:0]  X_curr_seq_num [p_num_be_lanes];
  logic                       X_curr_val     [p_num_be_lanes];
  logic [p_num_be_lanes-1:0]  X_curr_val_packed;

  always_comb begin
    for (int j = 0; j < p_num_be_lanes; j++) begin
      rob_input[j]          = X_curr[j];
      rob_input[j].wen      = ( X_curr[j].waddr == '0 ) ? 1'b0 : X_curr[j].wen;
      X_curr_seq_num[j]     = X_curr[j].seq_num;
      X_curr_val[j]         = X_curr[j].val & !fifo_empty;
      X_curr_val_packed[j]  = X_curr[j].val & !fifo_empty;
    end
  end

  logic                      deq_rdy;
  logic                      deq_msg_val        [p_num_be_lanes];
  logic [p_seq_num_bits-1:0] rob_output_seq_num [p_num_be_lanes];

  SSROB #(
    .p_depth     (p_rob_depth),
    .p_num_lanes (p_num_be_lanes),
    .p_msg_bits  ($bits(t_wb_msg))
  ) rob (
    .ins_idx     (X_curr_seq_num),
    .ins_msg     (rob_input),
    .ins_msg_val (X_curr_val),
    .ins_en      (|X_curr_val_packed),
    .ins_rdy     (),
    .avail_slots (avail_slots_ssrob),

    .deq_idx     (rob_output_seq_num),
    .deq_msg     (rob_output),
    .deq_msg_val (deq_msg_val),
    .deq_en      (deq_rdy),
    .deq_rdy     (deq_rdy),
    .*
  );

  generate
    for( i = 0; i < p_num_be_lanes; i++ ) begin: GEN_COMMIT_OUTPUT
      assign commit[i].pc      = rob_output[i].pc;
      assign local_commit[i].pc = rob_output[i].pc;
      assign commit[i].waddr   = rob_output[i].waddr;
      assign local_commit[i].waddr = rob_output[i].waddr;
      assign commit[i].wdata   = rob_output[i].wdata;
      assign local_commit[i].wdata = rob_output[i].wdata;
      assign commit[i].wen     = rob_output[i].wen;
      assign local_commit[i].wen = rob_output[i].wen;
      assign commit[i].ppreg                   = rob_output[i].ppreg;
      assign local_commit[i].ppreg             = rob_output[i].ppreg;
      assign commit[i].val                     = deq_msg_val[i] & deq_rdy;
      assign local_commit[i].val               = deq_msg_val[i] & deq_rdy;
      assign commit[i].seq_num                 = rob_output_seq_num[i];
      assign local_commit[i].seq_num           = rob_output_seq_num[i];
    end
  endgenerate

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS
  function int ceil_div_4( int val );
    return (val / 4) + ((val % 4) > 0 ? 1 : 0);
  endfunction

  // Helper arrays for commit (interfaces can't be runtime-indexed)
  logic                      commit_val     [p_num_be_lanes];
  logic [p_seq_num_bits-1:0] commit_seq_num [p_num_be_lanes];
  generate
    for( i = 0; i < p_num_be_lanes; i++ ) begin: GEN_COMMIT_VAL
      assign commit_val[i]     = commit[i].val;
      assign commit_seq_num[i] = commit[i].seq_num;
    end
  endgenerate

  // Per-lane data width (just the seq_num).
  function int lane_w_fn(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    lane_w_fn = ceil_div_4( p_seq_num_bits );
  endfunction

  // Total width of one side: lanes joined by ";" (1 char), padded to fit
  // the single-side header label ("arb" / "cmt", 3 chars).
  function int side_w_fn( int trace_level );
    int side_w;
    int hdr_w;
    side_w = p_num_be_lanes * lane_w_fn( trace_level )
             + (p_num_be_lanes - 1);
    hdr_w  = 2; // "WA" / "WC"
    side_w_fn = (hdr_w > side_w) ? hdr_w : side_w;
  endfunction

  function string trace(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    int    lane_w;
    int    side_w;
    int    n;
    string body;
    string cell_str;
    string pad;
    lane_w = lane_w_fn( trace_level );
    side_w = side_w_fn( trace_level );

    // Left side: instructions being arbitrated to this cycle.
    body = "";
    for( int i = 0; i < p_num_be_lanes; i++ ) begin
      if( i != 0 )
        body = {body, ";"};
      if( Ex_msg_sel[i].val )
        cell_str = $sformatf("%h", Ex_msg_sel[i].seq_num);
      else
        cell_str = {lane_w{" "}};
      body = {body, cell_str};
    end
    pad = "";
    for( n = body.len(); n < side_w; n = n + 1 )
      pad = {pad, " "};
    trace = {body, pad, " . "};

    // Right side: instructions being committed this cycle.
    body = "";
    for( int i = 0; i < p_num_be_lanes; i++ ) begin
      if( i != 0 )
        body = {body, ";"};
      if( commit_val[i] )
        cell_str = $sformatf("%h", commit_seq_num[i]);
      else
        cell_str = {lane_w{" "}};
      body = {body, cell_str};
    end
    pad = "";
    for( n = body.len(); n < side_w; n = n + 1 )
      pad = {pad, " "};
    trace = {trace, body, pad};
  endfunction

  `TRACE_HEADER_PAD_FN

  function string trace_header( int trace_level );
    trace_header = {th_pad( "WA", side_w_fn( trace_level ) ),
                    " . ",
                    th_pad( "WC", side_w_fn( trace_level ) )};
  endfunction
`endif

endmodule

`endif // HW_WRITEBACK_WRITEBACKCOMMITUNIT_V
