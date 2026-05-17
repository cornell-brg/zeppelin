//========================================================================
// FetchAddrGen.v
//========================================================================
// Generates memory request addresses for the fetch unit. Maintains the
// current fetch block base address and produces the request address and
// valid signal, accounting for control flow redirects and BP predictions.
//
// Also computes the redirect lane offset (for the squash tracker) from
// the raw ControlFlowNotif signals.

`ifndef HW_FETCH_FETCHADDRGEN_V
`define HW_FETCH_FETCHADDRGEN_V

`include "intf/ControlFlowNotif.v"

module FetchAddrGen
#(
  parameter p_num_fe_lanes       = 2,
  parameter p_max_in_flight      = 16,
  parameter p_rst_addr           = 32'h200,
  parameter p_enable_branch_pred = 0,

  // Derived parameters (do not override)
  parameter p_flight_bits   = $clog2(p_max_in_flight) + 1 > $clog2(p_num_fe_lanes) + 1
                               ? $clog2(p_max_in_flight) + 1
                               : $clog2(p_num_fe_lanes) + 1,
  parameter p_lane_idx_bits = p_num_fe_lanes > 1 ? $clog2(p_num_fe_lanes) : 1
)
(
  input  logic clk,
  input  logic rst,

  //----------------------------------------------------------------------
  // Control Flow Interface
  //----------------------------------------------------------------------

  ControlFlowNotif.sub ctrl_flow,

  //----------------------------------------------------------------------
  // Control inputs
  //----------------------------------------------------------------------

  input  logic        memreq_rdy,

  input  logic [p_flight_bits-1:0] num_in_flight,
  input  logic [p_flight_bits-1:0] num_to_squash,

  //----------------------------------------------------------------------
  // Branch Predictor Redirect
  //----------------------------------------------------------------------

  input  logic        bp_redirect_val,
  input  logic [31:0] bp_redirect_target,

  //----------------------------------------------------------------------
  // Outputs
  //----------------------------------------------------------------------

  output logic                       mem_req_val,
  output logic                [31:0] mem_req_addr,
  output logic                       memreq_xfer,
  output logic [p_lane_idx_bits-1:0] ctrl_flow_lane_offset
);

  //----------------------------------------------------------------------
  // Redirect address and block alignment
  //----------------------------------------------------------------------
  // ctrl_flow.target is always the branch destination (PC+imm). For a
  // not-taken misprediction, redirect to PC+4 (fall-through) instead.

  localparam logic [31:0] c_lane_stride = p_num_fe_lanes << 2;

  logic [31:0] redirect_addr;
  assign redirect_addr = ctrl_flow.taken ? ctrl_flow.target
                                         : (ctrl_flow.pc + 32'd4);

  // Block-align the redirect address and compute lane offset.
  logic [31:0] ctrl_flow_base_addr;

  generate
    if ( p_num_fe_lanes == 1 ) begin : gen_align_1

      assign ctrl_flow_lane_offset = '0;
      assign ctrl_flow_base_addr   = {redirect_addr[31:2], 2'b0};

    end else begin : gen_align_n

      localparam p_lane_bits = $clog2(p_num_fe_lanes);
      localparam logic [p_lane_bits:0] c_nfl = p_num_fe_lanes;

      logic [29:0] redirect_dividend;
      assign redirect_dividend = redirect_addr[31:2];

      // (redirect_addr >> 2) mod p_num_fe_lanes via bit-serial long
      // division. Must agree with the same computation in
      // BranchPredictor.v: BTB hits require FU's fetch sequence (started
      // from this block-aligned base) to land on the BP's stored
      // block_pc. The previous cascaded subtraction reduced only the
      // bottom (p_lane_bits+1) bits of pc>>2, which is correct only when
      // p_num_fe_lanes is a power of two.
      always_comb begin
        logic [p_lane_bits:0] r;
        r = '0;
        for ( int i = 29; i >= 0; i-- ) begin
          r = { r[p_lane_bits-1:0], redirect_dividend[i] };
          if ( r >= c_nfl )
            r = r - c_nfl;
        end
        ctrl_flow_lane_offset = r[p_lane_bits-1:0];
      end

      assign ctrl_flow_base_addr = redirect_addr - 32'({ctrl_flow_lane_offset, 2'b0});

    end
  endgenerate

  //----------------------------------------------------------------------
  // Current fetch block base address
  //----------------------------------------------------------------------

  logic [31:0] curr_fetch_block_base;

  generate
    if ( p_enable_branch_pred ) begin : gen_addr_bp

      always_ff @( posedge clk ) begin
        if ( rst )
          curr_fetch_block_base <= p_rst_addr;
        else if ( ctrl_flow.redirect_val & memreq_xfer )
          curr_fetch_block_base <= ctrl_flow_base_addr + c_lane_stride;
        else if ( ctrl_flow.redirect_val )
          curr_fetch_block_base <= ctrl_flow_base_addr;
        else if ( memreq_xfer & bp_redirect_val )
          curr_fetch_block_base <= bp_redirect_target;
        else if ( memreq_xfer )
          curr_fetch_block_base <= mem_req_addr + c_lane_stride;
      end

    end else begin : gen_addr_no_bp

      always_ff @( posedge clk ) begin
        if ( rst )
          curr_fetch_block_base <= p_rst_addr;
        else if ( ctrl_flow.redirect_val & memreq_xfer )
          curr_fetch_block_base <= ctrl_flow_base_addr + c_lane_stride;
        else if ( ctrl_flow.redirect_val )
          curr_fetch_block_base <= ctrl_flow_base_addr;
        else if ( memreq_xfer )
          curr_fetch_block_base <= mem_req_addr + c_lane_stride;
      end

      // Tie off unused BP inputs
      logic unused_bp;
      assign unused_bp = bp_redirect_val | (|bp_redirect_target);

    end
  endgenerate

  //----------------------------------------------------------------------
  // Request address and valid
  //----------------------------------------------------------------------

  always_comb begin
    if ( ctrl_flow.redirect_val )
      mem_req_addr = ctrl_flow_base_addr;
    else
      mem_req_addr = curr_fetch_block_base;
  end

  localparam logic [p_flight_bits-1:0] c_max_in_flight = p_max_in_flight[p_flight_bits-1:0];

  assign mem_req_val  = ctrl_flow.redirect_val |
                        (num_in_flight + num_to_squash < c_max_in_flight)
                        && !rst;
  assign memreq_xfer = mem_req_val & memreq_rdy;

endmodule

`endif // HW_FETCH_FETCHADDRGEN_V
