//========================================================================
// ControlFlowNotif.v
//========================================================================
// Notification interface for control flow events (redirects and branch
// predictor updates).
//
//   redirect_val  – fetch must redirect to target (misprediction or jump)
//   bp_update_val – branch/JAL resolution data is valid (for BP update)
//
// All events flow through the arbiter. The BP reads from the arbitrated
// grant.

`ifndef INTF_CONTROL_FLOW_NOTIF_V
`define INTF_CONTROL_FLOW_NOTIF_V

//------------------------------------------------------------------------
// ControlFlowNotif
//------------------------------------------------------------------------

interface ControlFlowNotif
#(
  parameter p_seq_num_bits  = 5
);

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Signals
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  logic [p_seq_num_bits-1:0] seq_num;       // instruction sequence number
  logic               [31:0] pc;            // instruction PC
  logic               [31:0] target;        // resolved target address
  logic                      taken;         // branch/jump taken
  logic                      bp_update_val; // BP update valid
  logic                      redirect_val;  // redirect valid


  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Module-facing Ports
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  // Publish
  modport pub (
    output seq_num,
    output pc,
    output target,
    output taken,
    output bp_update_val,
    output redirect_val
  );

  // Subscribe
  modport sub (
    input seq_num,
    input pc,
    input target,
    input taken,
    input bp_update_val,
    input redirect_val
  );

endinterface

`endif // INTF_CONTROL_FLOW_NOTIF_V
