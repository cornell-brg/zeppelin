//========================================================================
// BranchPredictor.v
//========================================================================
// A set-associative branch predictor with a Branch Target Buffer (BTB)
// and 2-bit saturating counters for direction prediction. The number of
// ways is parameterized: p_btb_ways=1 gives direct-mapped, and
// p_btb_ways=p_btb_entries gives fully-associative.
//
// Updates arrive via the ControlFlowNotif interface at execute time.
// FIFO replacement is used when all ways in a set are occupied.
//
// The prediction FIFO that tracks in-flight fetch redirections is managed
// externally by the fetch unit using the generic Fifo module.

`ifndef HW_FETCH_BRANCHPREDICTOR_V
`define HW_FETCH_BRANCHPREDICTOR_V

`include "intf/ControlFlowNotif.v"

module BranchPredictor
#(
  parameter p_btb_entries    = 2,
  parameter p_btb_ways       = 2,
  parameter p_num_fe_lanes   = 2,

  // Derived parameters (do not override)
  parameter p_eff_ways       = (p_btb_ways > p_btb_entries) ? p_btb_entries : p_btb_ways,
  parameter p_num_sets       = p_btb_entries / p_eff_ways,
  parameter p_set_idx_bits   = p_num_sets > 1 ? $clog2(p_num_sets) : 1,
  parameter p_tag_bits       = p_num_sets > 1 ? (32 - p_set_idx_bits - 2) : 30,
  parameter p_lane_idx_bits  = p_num_fe_lanes > 1 ? $clog2(p_num_fe_lanes) : 1,
  parameter p_way_idx_bits   = p_eff_ways > 1 ? $clog2(p_eff_ways) : 1
)
(
  input  logic clk,
  input  logic rst,

  //----------------------------------------------------------------------
  // Fetch Interface
  //----------------------------------------------------------------------

  input  logic [31:0]                req_pc,           // current fetch request address
  input  logic                       memreq_xfer,      // fetch request handshake completed
  output logic                       redirect_val,     // redirect fetch
  output logic                [31:0] redirect_target,  // predicted target
  output logic                       pred_taken,       // combinational prediction
  output logic [p_lane_idx_bits-1:0] branch_lane,      // branch lane offset

  //----------------------------------------------------------------------
  // Control Flow Interface
  //----------------------------------------------------------------------

  ControlFlowNotif.sub ctrl_flow
);

  //----------------------------------------------------------------------
  // BTB Storage — indexed by [set][way]
  //----------------------------------------------------------------------

  logic                          btb_valid       [p_num_sets][p_eff_ways];
  logic       [p_tag_bits-1:0]   btb_tag         [p_num_sets][p_eff_ways];
  logic                 [31:0]   btb_target      [p_num_sets][p_eff_ways];
  logic                  [1:0]   btb_counter     [p_num_sets][p_eff_ways];
  logic [p_lane_idx_bits-1:0]    btb_branch_lane [p_num_sets][p_eff_ways];

  // FIFO replacement pointer per set
  logic [p_way_idx_bits-1:0]     replace_ptr     [p_num_sets];

  //----------------------------------------------------------------------
  // Prediction (combinational)
  //----------------------------------------------------------------------

  logic [p_set_idx_bits-1:0] lookup_set;
  logic   [p_tag_bits-1:0]   lookup_tag;

  generate
    if ( p_num_sets > 1 ) begin : gen_lookup_multi_set
      assign lookup_set = req_pc[p_set_idx_bits+1:2];
      assign lookup_tag = req_pc[31:p_set_idx_bits+2];
    end else begin : gen_lookup_single_set
      assign lookup_set = '0;
      assign lookup_tag = req_pc[31:2];
    end
  endgenerate

  // Per-way hit detection
  logic                       way_hit     [p_eff_ways];
  logic                [31:0] way_target  [p_eff_ways];
  logic                 [1:0] way_counter [p_eff_ways];
  logic [p_lane_idx_bits-1:0] way_lane    [p_eff_ways];

  genvar gw;
  generate
    for ( gw = 0; gw < p_eff_ways; gw++ ) begin: WAY_LOOKUP
      assign way_hit[gw]     = btb_valid[lookup_set][gw] &
                                (btb_tag[lookup_set][gw] == lookup_tag);
      assign way_target[gw]  = btb_target[lookup_set][gw];
      assign way_counter[gw] = btb_counter[lookup_set][gw];
      assign way_lane[gw]    = btb_branch_lane[lookup_set][gw];
    end
  endgenerate

  // Reduce across ways — pick the matching way
  logic                       pred_hit;
  logic                [31:0] matched_target;
  logic                 [1:0] matched_counter;
  logic [p_lane_idx_bits-1:0] matched_lane;

  always_comb begin
    pred_hit        = 1'b0;
    matched_target  = '0;
    matched_counter = '0;
    matched_lane    = '0;
    for ( int w = 0; w < p_eff_ways; w++ ) begin
      if ( way_hit[w] ) begin
        pred_hit        = 1'b1;
        matched_target  = way_target[w];
        matched_counter = way_counter[w];
        matched_lane    = way_lane[w];
      end
    end
  end

  assign pred_taken      = pred_hit & matched_counter[1];
  assign redirect_val    = pred_taken & memreq_xfer & !ctrl_flow.redirect_val;
  assign redirect_target = matched_target;
  assign branch_lane     = matched_lane;

  //----------------------------------------------------------------------
  // Update (combinational, from ControlFlowNotif)
  //----------------------------------------------------------------------

  // Block-align the branch PC so the BTB set/tag matches the lookup
  // (which uses the fetch block base address, not the individual PC).
  // Compute lane offset via cascaded subtraction (same approach as
  // FetchAddrGen) to avoid an expensive modulo/division operator.
  localparam [31:0] c_lane_stride = p_num_fe_lanes << 2;

  logic                          update_val;
  logic   [p_set_idx_bits-1:0]   update_set;
  logic     [p_tag_bits-1:0]     update_tag;
  logic               [31:0]     update_target;
  logic                          update_taken;
  logic [p_lane_idx_bits-1:0]    update_branch_lane;

  logic [31:0] ctrl_flow_block_pc;

  generate
    if ( p_num_fe_lanes == 1 ) begin : gen_block_align_1

      assign ctrl_flow_block_pc = {ctrl_flow.pc[31:2], 2'b0};

    end else begin : gen_block_align_n

      localparam p_lane_bits = $clog2(p_num_fe_lanes);
      localparam logic [p_lane_bits:0] c_nfl = p_num_fe_lanes;

      logic [29:0]            bp_dividend;
      logic [p_lane_bits-1:0] bp_lane_offset;

      assign bp_dividend = ctrl_flow.pc[31:2];

      // (ctrl_flow.pc >> 2) mod p_num_fe_lanes via bit-serial long
      // division: a chain of (p_lane_bits+1)-wide compare-subtract stages,
      // one per dividend bit, MSB first. Truncating pc>>2 to a few low
      // bits before reducing mod N (as the prior cascaded-subtraction
      // did) only matches the FU's fetch alignment for power-of-2 lane
      // counts; for 3/5/6/7 lanes it yields a block_pc the FU never
      // actually fetches, so BTB hits silently never happen.
      always_comb begin
        logic [p_lane_bits:0] r;
        r = '0;
        for ( int i = 29; i >= 0; i-- ) begin
          r = { r[p_lane_bits-1:0], bp_dividend[i] };
          if ( r >= c_nfl )
            r = r - c_nfl;
        end
        bp_lane_offset = r[p_lane_bits-1:0];
      end

      assign ctrl_flow_block_pc =
        ctrl_flow.pc - 32'({bp_lane_offset, 2'b0});

    end
  endgenerate

  assign update_val         = ctrl_flow.bp_update_val;
  assign update_target      = ctrl_flow.target;
  assign update_taken       = ctrl_flow.taken;
  assign update_branch_lane = p_lane_idx_bits'((ctrl_flow.pc - ctrl_flow_block_pc) >> 2);

  generate
    if ( p_num_sets > 1 ) begin : gen_update_multi_set
      assign update_set = ctrl_flow_block_pc[p_set_idx_bits+1:2];
      assign update_tag = p_tag_bits'(ctrl_flow_block_pc >> (p_set_idx_bits + 2));
    end else begin : gen_update_single_set
      assign update_set = '0;
      assign update_tag = p_tag_bits'(ctrl_flow_block_pc >> 2);
    end
  endgenerate

  // Find matching way or indicate miss
  logic                      update_way_hit;
  logic [p_way_idx_bits-1:0] update_way_idx;

  always_comb begin
    update_way_hit = 1'b0;
    update_way_idx = '0;
    for ( int w = 0; w < p_eff_ways; w++ ) begin
      if ( btb_valid[update_set][w] & (btb_tag[update_set][w] == update_tag) ) begin
        update_way_hit = 1'b1;
        update_way_idx = p_way_idx_bits'(unsigned'(w));
      end
    end
  end

  // The way to actually write: matching way on hit, replace_ptr on miss
  logic [p_way_idx_bits-1:0] write_way;
  assign write_way = update_way_hit ? update_way_idx : replace_ptr[update_set];

  always_ff @( posedge clk ) begin
    if ( rst ) begin
      for ( int s = 0; s < p_num_sets; s++ ) begin
        replace_ptr[s] <= '0;
        for ( int w = 0; w < p_eff_ways; w++ )
          btb_valid[s][w] <= 1'b0;
      end
    end else if ( update_val ) begin
      btb_valid[update_set][write_way]       <= 1'b1;
      btb_tag[update_set][write_way]         <= update_tag;
      btb_target[update_set][write_way]      <= update_target;
      btb_branch_lane[update_set][write_way] <= update_branch_lane;

      // 2-bit saturating counter update
      if ( update_way_hit ) begin
        // Existing entry — increment or decrement
        if ( update_taken ) begin
          if ( btb_counter[update_set][write_way] != 2'b11 )
            btb_counter[update_set][write_way] <= btb_counter[update_set][write_way] + 2'b01;
        end else begin
          if ( btb_counter[update_set][write_way] != 2'b00 )
            btb_counter[update_set][write_way] <= btb_counter[update_set][write_way] - 2'b01;
        end
      end else begin
        // New entry — initialize counter, advance FIFO pointer
        btb_counter[update_set][write_way] <= update_taken ? 2'b10 : 2'b01;
        if ( p_eff_ways > 1 ) begin
          if ( replace_ptr[update_set] == p_way_idx_bits'(unsigned'(p_eff_ways - 1)) )
            replace_ptr[update_set] <= '0;
          else
            replace_ptr[update_set] <= replace_ptr[update_set] + p_way_idx_bits'(1);
        end
      end
    end
  end

endmodule

`endif // HW_FETCH_BRANCHPREDICTOR_V
