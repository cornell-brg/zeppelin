//========================================================================
// SingleCycleMulIterativeDivRem.v
//========================================================================
// Hybrid unit: single-cycle multiplier for MUL/MULH/MULHSU/MULHU,
// iterative divider for DIV/DIVU/REM/REMU. Same D__XIntf / X__WIntf
// interface as the other MulDivRem variants.

`ifndef HW_EXECUTE_SINGLECYCLEMULITERATIVEDIVREM_V
`define HW_EXECUTE_SINGLECYCLEMULITERATIVEDIVREM_V

`include "defs/UArch.v"
`include "hw/common/Fifo.v"
`include "hw/util/TraceHeader.v"
`include "intf/D__XIntf.v"
`include "intf/X__WIntf.v"

import UArch::*;

//------------------------------------------------------------------------
// IterativeDivRemStep
//------------------------------------------------------------------------
// Computes one step of an iterative division or remainder.

module IterativeDivRemStep (
  input  logic [63:0] a,
  input  logic [63:0] b,
  input  logic [32:0] b_shift,
  input  rv_uop       uop,
  input  logic [63:0] result,

  output logic [63:0] next_a,
  output logic [63:0] next_b,
  output logic [32:0] next_b_shift,
  output logic [63:0] next_result,
  output logic        done
);

  logic [63:0] abs_a;       // Absolute value of a
  logic [63:0] adj_b;       // Value of b to take from a
  logic [63:0] adj_b_shift; // Value to add to the result

  always_comb begin
    if( a[63] ) begin
      abs_a       = ~a + 1;
      adj_b       = ~b + 1;
      adj_b_shift = ~{31'b0, b_shift} + 1;
    end else begin
      abs_a       = a;
      adj_b       = b;
      adj_b_shift = {31'b0, b_shift};
    end
  end

  logic is_signed_op;
  logic is_rem_op;

  assign is_signed_op = ( uop == OP_DIV  ) | ( uop == OP_REM  );
  assign is_rem_op    = ( uop == OP_REM  ) | ( uop == OP_REMU );

  always_comb begin
    // next_a: subtract divisor from dividend when it fits
    if( is_signed_op )
      next_a = ( abs_a >= b ) ? a - adj_b : a;
    else
      next_a = (     a >= b ) ? a - b     : a;

    // next_b: arithmetic shift for signed, logical for unsigned
    if( is_signed_op )
      next_b = $signed(b) >>> 1;
    else
      next_b = b >> 1;

    next_b_shift = b_shift >> 1;

    // next_result: quotient accumulation for div, remainder for rem
    if( is_rem_op ) begin
      next_result = next_a;
    end else if( is_signed_op ) begin
      next_result = ( abs_a >= b ) ? result + adj_b_shift        : result;
    end else begin
      next_result = (     a >= b ) ? result | { 31'b0, b_shift } : result;
    end

    done = ( next_b_shift == '0 ) | ( next_a == '0 );

    // Handling divide-by-zero
    if( b == '0 ) begin
      if( is_rem_op ) begin
        next_result = a;
        done        = 1'b1;
      end else begin
        next_result = {64{1'b1}};
        done        = 1'b1;
      end
    end

    // Handling signed overflow: -2^31 / -1
    if( is_signed_op &
        ( b[63:32] == 'hffffffff ) & ( a[31:0] == 'h80000000 ) ) begin
      if( is_rem_op ) begin
        next_result = '0;
        done        = 1'b1;
      end else begin
        next_result = {32'b0, 'h80000000};
        done        = 1'b1;
      end
    end
  end
endmodule

//------------------------------------------------------------------------
// SingleCycleMulIterativeDivRem
//------------------------------------------------------------------------

module SingleCycleMulIterativeDivRem #(
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

  typedef enum {
    IDLE,
    SWAP_SIGN,
    CALC,
    RESTORE_SIGN,
    DONE
  } state_t;

  state_t next_state;
  state_t curr_state;

  logic fifo_full, fifo_empty;
  logic fifo_push, fifo_pop;
  logic W_xfer;

  assign fifo_push = D.val & (!fifo_full | fifo_pop);
  assign W_xfer    = W.val & W.rdy;
  assign fifo_pop  = (curr_state == DONE) & W.rdy & !fifo_empty;

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
  // Detect multiply vs div/rem
  //----------------------------------------------------------------------

  logic is_mul_op;
  assign is_mul_op = ( D_curr.uop == OP_MUL    ) |
                     ( D_curr.uop == OP_MULH   ) |
                     ( D_curr.uop == OP_MULHU  ) |
                     ( D_curr.uop == OP_MULHSU );

  //----------------------------------------------------------------------
  // Single-cycle multiplier (MUL/MULH/MULHSU/MULHU)
  //----------------------------------------------------------------------

  logic signed [63:0] mul_a, mul_b;

  always_comb begin
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

  logic signed [63:0] product;
  assign product = mul_a * mul_b;

  logic [31:0] mul_result;

  always_comb begin
    case( D_curr.uop )
      OP_MUL:    mul_result = product[31:0];
      OP_MULH:   mul_result = product[63:32];
      OP_MULHSU: mul_result = product[63:32];
      OP_MULHU:  mul_result = product[63:32];
      default:   mul_result = 'x;
    endcase
  end

  //----------------------------------------------------------------------
  // Iterative divider state machine (DIV/DIVU/REM/REMU)
  //----------------------------------------------------------------------

  always_ff @( posedge clk ) begin
    if( rst )
      curr_state <= IDLE;
    else
      curr_state <= next_state;
  end

  logic calc_done;
  logic need_to_sign_restore;

  always_comb begin
    next_state = curr_state;

    case( curr_state )
      IDLE: if( !fifo_empty ) begin
        if( is_mul_op )
          next_state = DONE;          // MUL ops complete in one cycle
        else if(
          D_curr.op2[31] &
          ( D_curr.uop == OP_DIV | D_curr.uop == OP_REM )
        )    next_state = SWAP_SIGN;
        else next_state = CALC;
      end

      SWAP_SIGN: next_state = CALC;

      CALC: if( calc_done ) begin
        if( need_to_sign_restore ) next_state = RESTORE_SIGN;
        else                       next_state = DONE;
      end

      RESTORE_SIGN: next_state = DONE;

      DONE: if( W_xfer ) begin
        next_state = IDLE;
      end
    endcase
  end

  logic  initialize;
  assign initialize = ( next_state == SWAP_SIGN ) |
                      (( next_state == CALC ) & !( curr_state == SWAP_SIGN ) & !( curr_state == CALC ));

  //----------------------------------------------------------------------
  // Initial values for opa and opb (div/rem only)
  //----------------------------------------------------------------------

  logic [63:0] init_opa, init_opb;

  always_comb begin
    case( D_curr.uop )
      OP_DIV:    init_opa = { {32{D_curr.op1[31]}}, D_curr.op1 };
      OP_DIVU:   init_opa = { 32'b0,                D_curr.op1 };
      OP_REM:    init_opa = { {32{D_curr.op1[31]}}, D_curr.op1 };
      OP_REMU:   init_opa = { 32'b0,                D_curr.op1 };
      default:   init_opa = 'x;
    endcase

    case( D_curr.uop )
      OP_DIV:    init_opb = { D_curr.op2,            32'b0 };
      OP_DIVU:   init_opb = { D_curr.op2,            32'b0 };
      OP_REM:    init_opb = { D_curr.op2,            32'b0 };
      OP_REMU:   init_opb = { D_curr.op2,            32'b0 };
      default:   init_opb = 'x;
    endcase
  end

  //----------------------------------------------------------------------
  // Iterative calculation
  //----------------------------------------------------------------------

  always_ff @( posedge clk ) begin
    if( initialize )
      need_to_sign_restore <= 1'b0;
    else if( curr_state == SWAP_SIGN )
      // Need to ensure that the sign is the same as dividend
      need_to_sign_restore <= ( D_curr.uop == OP_REM );
  end

  logic [63:0] opa,      opb;
  logic [63:0] next_opa, next_opb;
  logic [32:0] b_shift,  next_b_shift;
  logic [63:0] div_result, next_div_result;

  always_ff @( posedge clk ) begin
    if( curr_state == CALC ) begin
      opa        <= next_opa;
      opb        <= next_opb;
      b_shift    <= next_b_shift;
      div_result <= next_div_result;
    end else if( curr_state == SWAP_SIGN ) begin
      // Need to make sure that opb is positive
      opa        <= ~opa + 1;
      opb        <= ~opb + 1;
    end else if( curr_state == RESTORE_SIGN ) begin
      // Need to fix sign for remainder
      div_result <= ~div_result + 1;
    end else if( initialize ) begin
      opa        <= init_opa;
      opb        <= init_opb;
      b_shift    <= { 1'b1, 32'b0 };
      div_result <= 64'b0;
    end
  end

  IterativeDivRemStep div_rem_step (
    .a       (opa),
    .b       (opb),
    .b_shift (b_shift),
    .uop     (D_curr.uop),
    .result  (div_result),

    .next_a       (next_opa),
    .next_b       (next_opb),
    .next_b_shift (next_b_shift),
    .next_result  (next_div_result),
    .done         (calc_done)
  );

  //----------------------------------------------------------------------
  // Assign outputs
  //----------------------------------------------------------------------

  assign D.rdy = !fifo_full | fifo_pop;

  assign W.val     = ( curr_state == DONE );
  assign W.pc      = D_curr.pc;
  assign W.seq_num = D_curr.seq_num;
  assign W.waddr   = D_curr.waddr;
  assign W.preg    = D_curr.preg;
  assign W.ppreg                  = D_curr.ppreg;
  assign W.wen                    = 1'b1;

  always_comb begin
    if( is_mul_op )
      W.wdata = mul_result;
    else begin
      case( D_curr.uop )
        OP_DIV:    W.wdata = div_result[31:0];
        OP_DIVU:   W.wdata = div_result[31:0];
        OP_REM:    W.wdata = div_result[31:0];
        OP_REMU:   W.wdata = div_result[31:0];
        default:   W.wdata = 'x;
      endcase
    end
  end

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

`ifndef SYNTHESIS

  function int ceil_div_4( int val );
    return (val / 4) + ((val % 4) > 0 ? 1 : 0);
  endfunction

  function string state_str();
    if( curr_state == IDLE )
      return "I";
    if( curr_state == SWAP_SIGN )
      return "S";
    if( curr_state == CALC )
      return "C";
    if( curr_state == RESTORE_SIGN )
      return "R";
    else // Done
      return "D";
  endfunction

  // Plain-net mirrors of interface signals read by trace(). See ALU for
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
    if( curr_state == IDLE ) begin
      body = "";
    end else if( curr_state == DONE ) begin
      if( w_val_mir & !w_rdy_mir )
        body = "#";
      else
        body = $sformatf("%h", w_seq_num_mir);
    end else begin
      body = "CC";
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

`endif // HW_EXECUTE_SINGLECYCLEMULITERATIVEDIVREM_V
