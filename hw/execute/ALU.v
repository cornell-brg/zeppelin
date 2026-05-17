//========================================================================
// ALU.v
//========================================================================
// An execute unit for performing arithmetic operations

`ifndef HW_EXECUTE_ALU_V
`define HW_EXECUTE_ALU_V

`include "defs/UArch.v"
`include "hw/common/Fifo.v"
`include "hw/util/TraceHeader.v"
`include "intf/D__XIntf.v"
`include "intf/X__WIntf.v"

import UArch::*;

module ALU #(
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

  X__WIntf.X_intf W
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
    logic                  [4:0] waddr;
    rv_uop                       uop;
    logic [p_phys_addr_bits-1:0] preg;
    logic [p_phys_addr_bits-1:0] ppreg;
  } D_input;

  // verilator lint_off ENUMVALUE

  D_input fifo_in;
  assign fifo_in = '{
    val:     1'b1,
    pc:      D.pc,
    seq_num: D.seq_num,
    op1:     D.op1,
    op2:     D.op2,
    waddr:   D.waddr,
    uop:     D.uop,
    preg:    D.preg,
    ppreg:   D.ppreg
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
  // Arithmetic Operations
  //----------------------------------------------------------------------

  logic [31:0] op1, op2;
  assign op1 = D_curr.op1;
  assign op2 = D_curr.op2;

  rv_uop uop;
  assign uop = D_curr.uop;

  always_comb begin
    case( uop )
      OP_ADD:   W.wdata = op1 + op2;
      OP_SUB:   W.wdata = op1 - op2;
      OP_AND:   W.wdata = op1 & op2;
      OP_OR:    W.wdata = op1 | op2;
      OP_XOR:   W.wdata = op1 ^ op2;
      OP_SLT:   W.wdata = { 31'b0, ($signed(op1) <  $signed(op2))};
      OP_SLTU:  W.wdata = { 31'b0, (op1          <  op2         )};
      OP_SRA:   W.wdata = $signed(op1) >>> op2[4:0];
      OP_SRL:   W.wdata = op1           >> op2[4:0];
      OP_SLL:   W.wdata = op1           << op2[4:0];
      OP_LUI:   W.wdata = op2;
      OP_AUIPC: W.wdata = D_curr.pc + op2;
      default:  W.wdata = 'x;
    endcase
  end

  //----------------------------------------------------------------------
  // Assign remaining signals
  //----------------------------------------------------------------------

  assign D.rdy = !fifo_full | fifo_pop;
  assign W.val = !fifo_empty;

  assign W.pc      = D_curr.pc;
  assign W.wen     = 1'b1;
  assign W.seq_num = D_curr.seq_num;
  assign W.waddr   = D_curr.waddr;
  assign W.preg    = D_curr.preg;
  assign W.ppreg                  = D_curr.ppreg;

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS
  function int ceil_div_4( int val );
    return (val / 4) + ((val % 4) > 0 ? 1 : 0);
  endfunction

  // Plain-net mirrors of the interface signals read by trace(). VCS does not
  // track sensitivity through modport reads that happen inside a function body,
  // so the trace-string continuous assigns below never re-evaluate if they read
  // W.* directly. Mirroring into plain logic nets (direct continuous assigns,
  // which VCS does track) sidesteps this.
  logic                      w_val_mir;
  logic                      w_rdy_mir;
  logic [p_seq_num_bits-1:0] w_seq_num_mir;
  assign w_val_mir     = W.val;
  assign w_rdy_mir     = W.rdy;
  assign w_seq_num_mir = W.seq_num;

  function int lane_w_fn(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    // Lane width = max(seq, 3) — seq when running, "(#)" when stalled.
    lane_w_fn = (ceil_div_4( p_seq_num_bits ) > 2) ?
                 ceil_div_4( p_seq_num_bits ) : 2;
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
    if( w_val_mir ) begin
      if( !w_rdy_mir )
        body = "#";
      else
        body = $sformatf("%h", w_seq_num_mir);
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
    trace_header = th_pad( "AL", lane_w_fn( trace_level ) );
  endfunction

  string tr, th;
  always_comb begin
    tr = trace(0);
    th = trace_header(0);
  end
`endif

endmodule

`endif // HW_EXECUTE_ALU_V
