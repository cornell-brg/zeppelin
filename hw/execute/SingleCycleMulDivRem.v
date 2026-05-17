//========================================================================
// SingleCycleMulDivRemL7.v
//========================================================================
// A single-cycle unit capable of computing a multiply, division, or
// remainder. Drop-in replacement for IterativeMulDivRemL7 with the same
// D__XIntf / X__WIntf interface but purely combinational datapath.

`ifndef HW_EXECUTE_EXECUTE_VARIANTS_L7_SINGLECYCLEMULDIVREML7_V
`define HW_EXECUTE_EXECUTE_VARIANTS_L7_SINGLECYCLEMULDIVREML7_V

`include "defs/UArch.v"
`include "hw/common/Fifo.v"
`include "hw/util/TraceHeader.v"
`include "intf/D__XIntf.v"
`include "intf/X__WIntf.v"

import UArch::*;

module SingleCycleMulDivRemL7 #(
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
  logic W_xfer;

  assign W_xfer    = W.val & W.rdy;
  assign fifo_pop  = W_xfer & !fifo_empty;
  assign fifo_push = D.val & (!fifo_full | fifo_pop);

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
  // Single unsigned divider with sign correction
  //----------------------------------------------------------------------
  // Convert operands to unsigned, do one divide, then fix up signs.

  logic        is_signed_op;
  logic        is_rem_op;
  logic        a_neg, b_neg;
  logic [31:0] abs_a, abs_b;
  logic [31:0] udiv_quot;
  logic [31:0] div_quot, div_rem;

  assign is_signed_op = (D_curr.uop == OP_DIV) || (D_curr.uop == OP_REM);
  assign is_rem_op    = (D_curr.uop == OP_REM) || (D_curr.uop == OP_REMU);
  assign a_neg        = is_signed_op & D_curr.op1[31];
  assign b_neg        = is_signed_op & D_curr.op2[31];
  assign abs_a        = a_neg ? (~D_curr.op1 + 32'd1) : D_curr.op1;
  assign abs_b        = b_neg ? (~D_curr.op2 + 32'd1) : D_curr.op2;

  assign udiv_quot = abs_a / abs_b;
  assign div_quot = (a_neg ^ b_neg) ? (~udiv_quot + 32'd1) : udiv_quot;

  //----------------------------------------------------------------------
  // Single multiplier shared between MUL* and REM* ops
  //----------------------------------------------------------------------
  // For MUL/MULH/MULHSU/MULHU: multiply sign/zero-extended operands.
  // For REM/REMU: compute quot * b so remainder = a - quot * b.
  // Only one uop executes at a time, so inputs are safely muxed.

  logic signed [63:0] mul_a, mul_b;

  always_comb begin
    if( is_rem_op ) begin                        // rem: quot * divisor
      mul_a = $signed({32'b0, udiv_quot});
      mul_b = $signed({32'b0, abs_b});
    end else begin
      case( D_curr.uop )
        OP_MUL, OP_MULH: begin                   // s x s
          mul_a = $signed({{32{D_curr.op1[31]}}, D_curr.op1});
          mul_b = $signed({{32{D_curr.op2[31]}}, D_curr.op2});
        end
        OP_MULHSU: begin                          // s x u
          mul_a = $signed({{32{D_curr.op1[31]}}, D_curr.op1});
          mul_b = $signed({32'b0, D_curr.op2});
        end
        default: begin                            // u x u (MULHU)
          mul_a = $signed({32'b0, D_curr.op1});
          mul_b = $signed({32'b0, D_curr.op2});
        end
      endcase
    end
  end

  logic signed [63:0] product;
  assign product = mul_a * mul_b;

  // Remainder = abs_a - (quot * abs_b), then sign-correct
  logic [31:0] udiv_rem;
  assign udiv_rem = abs_a - product[31:0];
  assign div_rem  = a_neg ? (~udiv_rem + 32'd1) : udiv_rem;

  //----------------------------------------------------------------------
  // Result selection
  //----------------------------------------------------------------------

  logic [31:0] result;

  always_comb begin
    case( D_curr.uop )
      OP_MUL:    result = product[31:0];
      OP_MULH:   result = product[63:32];
      OP_MULHSU: result = product[63:32];
      OP_MULHU:  result = product[63:32];
      OP_DIV: begin
        if( D_curr.op2 == 32'd0 )
          result = 32'hFFFFFFFF;
        else if( D_curr.op1 == 32'h80000000 && D_curr.op2 == 32'hFFFFFFFF )
          result = 32'h80000000;
        else
          result = div_quot;
      end
      OP_DIVU: begin
        if( D_curr.op2 == 32'd0 )
          result = 32'hFFFFFFFF;
        else
          result = udiv_quot;
      end
      OP_REM: begin
        if( D_curr.op2 == 32'd0 )
          result = D_curr.op1;
        else if( D_curr.op1 == 32'h80000000 && D_curr.op2 == 32'hFFFFFFFF )
          result = 32'd0;
        else
          result = div_rem;
      end
      OP_REMU: begin
        if( D_curr.op2 == 32'd0 )
          result = D_curr.op1;
        else
          result = udiv_rem;
      end
      default: result = 'x;
    endcase
  end

  //----------------------------------------------------------------------
  // Assign outputs
  //----------------------------------------------------------------------

  assign D.rdy = !fifo_full | fifo_pop;

  assign W.val     = !fifo_empty;
  assign W.pc      = D_curr.pc;
  assign W.seq_num = D_curr.seq_num;
  assign W.waddr   = D_curr.waddr;
  assign W.preg    = D_curr.preg;
  assign W.ppreg                  = D_curr.ppreg;
  assign W.wen                    = 1'b1;
  assign W.wdata   = result;

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS

  function int ceil_div_4( int val );
    return (val / 4) + ((val % 4) > 0 ? 1 : 0);
  endfunction

  // Plain-net mirrors of interface signals read by trace(). See ALUL6 for
  // rationale (VCS sensitivity workaround).
  logic                      w_val_mir;
  logic                      w_rdy_mir;
  logic [p_seq_num_bits-1:0] w_seq_num_mir;
  assign w_val_mir     = W.val;
  assign w_rdy_mir     = W.rdy;
  assign w_seq_num_mir = W.seq_num;

  localparam int p_compact_w = (ceil_div_4(p_seq_num_bits) > 2) ?
                                 ceil_div_4(p_seq_num_bits) : 2; // max(seq, "#")

  function string trace(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    int    n;
    string body;
    string pad;
    if( !fifo_empty ) begin
      if( w_val_mir & !w_rdy_mir )
        body = "#";
      else
        body = $sformatf("%h", w_seq_num_mir);
    end else begin
      body = "";
    end
    pad = "";
    for( n = body.len(); n < p_compact_w; n = n + 1 )
      pad = {pad, " "};
    trace = {body, pad};
  endfunction

  `TRACE_HEADER_PAD_FN

  function string trace_header(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    trace_header = th_pad( "ML", p_compact_w );
  endfunction

  string tr, th;
  always_comb begin
    tr = trace(0);
    th = trace_header(0);
  end
`endif

endmodule

`endif // HW_EXECUTE_EXECUTE_VARIANTS_L7_SINGLECYCLEMULDIVREML7_V
