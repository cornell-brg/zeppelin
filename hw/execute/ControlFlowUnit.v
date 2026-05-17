//========================================================================
// ControlFlowUnit.v
//========================================================================
// An execute unit for handling control flow operations (conditional
// and unconditional)

`ifndef HW_EXECUTE_CONTROLFLOWUNIT_V
`define HW_EXECUTE_CONTROLFLOWUNIT_V

`include "defs/UArch.v"
`include "hw/common/Fifo.v"
`include "hw/util/TraceHeader.v"
`include "intf/D__XIntf.v"
`include "intf/ControlFlowNotif.v"
`include "intf/X__WIntf.v"

import UArch::*;

module ControlFlowUnit #(
  parameter p_d_intf_fifo_depth = 1
)(
  input  logic clk,
  input  logic rst,

  //----------------------------------------------------------------------
  // D <-> X Interface
  //----------------------------------------------------------------------

  D__XIntf.X_intf D,

  //----------------------------------------------------------------------
  // X <-> W Interface
  //----------------------------------------------------------------------

  X__WIntf.X_intf W,

  //----------------------------------------------------------------------
  // Control Flow Notification
  //----------------------------------------------------------------------

  ControlFlowNotif.pub ctrl_flow
);

  localparam p_seq_num_bits   = D.p_seq_num_bits;
  localparam p_phys_addr_bits = D.p_phys_addr_bits;

  //----------------------------------------------------------------------
  // Bypass FIFO for D interface
  //----------------------------------------------------------------------

  typedef struct packed {
    logic                        val;
    logic                 [31:0] pc;
    logic   [p_seq_num_bits-1:0] seq_num;
    logic                 [31:0] op1;
    logic                 [31:0] op2;
    logic                 [31:0] imm;
    logic                  [4:0] waddr;
    rv_uop                       uop;
    logic [p_phys_addr_bits-1:0] preg;
    logic [p_phys_addr_bits-1:0] ppreg;
    logic                        predicted_taken;
  } D_input;

  // verilator lint_off ENUMVALUE

  D_input fifo_in;
  assign fifo_in = '{
    val:             1'b1,
    pc:              D.pc,
    seq_num:         D.seq_num,
    op1:             D.op1,
    op2:             D.op2,
    imm:             D.op3.branch_imm,
    waddr:           D.waddr,
    uop:             D.uop,
    preg:            D.preg,
    ppreg:           D.ppreg,
    predicted_taken: D.predicted_taken
  };

  // verilator lint_on ENUMVALUE

  logic fifo_full, fifo_empty;
  logic fifo_push, fifo_pop;

  assign fifo_push = D.val & (!fifo_full | fifo_pop);
  assign fifo_pop  = !fifo_empty & W.rdy;

  D_input D_curr;

  Fifo #(
    .p_entry_bits ($bits(D_input)),
    .p_depth      (p_d_intf_fifo_depth)
  ) d_fifo (
    .clk   (clk),
    .rst   (rst),
    .clear (1'b0),
    .push  (fifo_push),
    .pop   (fifo_pop),
    .empty (fifo_empty),
    .full  (fifo_full),
    .wdata (fifo_in),
    .rdata (D_curr)
  );

  //----------------------------------------------------------------------
  // Determine ctrl_flow condition
  //----------------------------------------------------------------------

  logic should_branch;

  always_comb begin
    case( D_curr.uop )
      OP_BEQ:   should_branch = ( D_curr.op1 == D_curr.op2 );
      OP_BNE:   should_branch = ( D_curr.op1 != D_curr.op2 );
      OP_BLT:   should_branch = ( $signed(D_curr.op1) <  $signed(D_curr.op2) );
      OP_BGE:   should_branch = ( $signed(D_curr.op1) >= $signed(D_curr.op2) );
      OP_BLTU:  should_branch = ( D_curr.op1 <  D_curr.op2 );
      OP_BGEU:  should_branch = ( D_curr.op1 >= D_curr.op2 );
      OP_JAL:   should_branch = 1'b0;
      OP_JALR:  should_branch = 1'b0;
      default:  should_branch = 1'bx;
    endcase
  end

  logic ctrl_flow_sent;
  always_ff @( posedge clk ) begin
    if( rst )
      ctrl_flow_sent <= 1'b0;
    else if( fifo_pop )
      ctrl_flow_sent <= 1'b0;
    else if( !fifo_empty )
      ctrl_flow_sent <= 1'b1;
  end

  // Misprediction: actual outcome differs from prediction.
  // Only applies to conditional branches — JAL/JALR are handled by DIU.
  logic is_cond_branch;
  assign is_cond_branch = (D_curr.uop != OP_JAL) & (D_curr.uop != OP_JALR);

  logic mispredict;
  assign mispredict = is_cond_branch & (should_branch != D_curr.predicted_taken);

  // Redirect on misprediction only; BP update on every conditional branch
  assign ctrl_flow.redirect_val  = !fifo_empty & mispredict & !ctrl_flow_sent;
  assign ctrl_flow.bp_update_val = !fifo_empty & is_cond_branch & !ctrl_flow_sent;
  assign ctrl_flow.pc            = D_curr.pc;
  // Always send PC+imm as target (the branch destination). The redirect
  // consumer computes the actual redirect address from target and taken.
  assign ctrl_flow.target        = D_curr.pc + D_curr.imm;
  assign ctrl_flow.taken         = should_branch;
  assign ctrl_flow.seq_num       = D_curr.seq_num;

  //----------------------------------------------------------------------
  // Determine register write
  //----------------------------------------------------------------------

  always_comb begin
    case( D_curr.uop )
      OP_BNE:  W.wen = 1'b0;
      OP_JAL:  W.wen = 1'b1;
      OP_JALR: W.wen = 1'b1;
      default: W.wen = 1'bx;
    endcase
  end

  assign W.wdata = D_curr.pc + 32'd4;

  //----------------------------------------------------------------------
  // Remaining signals
  //----------------------------------------------------------------------

  assign W.pc                     = D_curr.pc;
  assign W.waddr                  = D_curr.waddr;
  assign W.seq_num                = D_curr.seq_num;
  assign W.preg                   = D_curr.preg;
  assign W.ppreg                  = D_curr.ppreg;

  //----------------------------------------------------------------------
  // Assign remaining signals
  //----------------------------------------------------------------------

  assign D.rdy = !fifo_full | fifo_pop;
  assign W.val = !fifo_empty;

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS
  function int ceil_div_4( int val );
    return (val / 4) + ((val % 4) > 0 ? 1 : 0);
  endfunction

  function int lane_w_fn(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    int data_w;
    int hdr_w;
    data_w    = ceil_div_4( p_seq_num_bits ); // seq, or "(#)" via hdr_w floor
    hdr_w     = 2; // "CL" / "(#)"
    lane_w_fn = (hdr_w > data_w) ? hdr_w : data_w;
  endfunction

  function string trace(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    int    lane_w;
    int    n;
    string body;
    string pad;
    lane_w = lane_w_fn( trace_level );
    if( W.val ) begin
      if( !W.rdy )
        body = "#";
      else
        body = $sformatf("%h", W.seq_num);
    end else begin
      body = "";
    end
    pad = "";
    for( n = body.len(); n < lane_w; n = n + 1 )
      pad = {pad, " "};
    trace = {body, pad};
  endfunction

  `TRACE_HEADER_PAD_FN

  function string trace_header( int trace_level );
    trace_header = th_pad( "CL", lane_w_fn( trace_level ) );
  endfunction
`endif

endmodule

`endif // HW_EXECUTE_CONTROLFLOWUNIT_V
