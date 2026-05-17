//========================================================================
// DIUCtrlFlowPublisher.v
//========================================================================
// Combinational ctrl_flow publisher for the decode-issue unit.
//
// When the oldest control instruction is a JAL/JALR (not a branch),
// computes its jump target and publishes a combinational ctrl_flow
// notification.  This is safe because CtrlFlowUnit decouples the DIU's
// grant from its own request, breaking the combinational loop.

`ifndef HW_DECODEISSUE_DIUCTRLFLOWPUBLISHER_V
`define HW_DECODEISSUE_DIUCTRLFLOWPUBLISHER_V

`include "intf/ControlFlowNotif.v"

module DIUCtrlFlowPublisher #(
  parameter type t_ctrl_info    = logic,
  parameter      p_seq_num_bits = 5
) (
  // Oldest control instruction info (bundled struct)
  input t_ctrl_info oldest_ctrl_inst,

  // Signals not in the struct (depend on external state)
  input logic [31:0] oldest_ctrl_inst_jump_base,
  input logic        oldest_ctrl_inst_dispatch_go,

  // CtrlFlow notification
  ControlFlowNotif.pub ctrl_flow_pub
);

  //----------------------------------------------------------------------
  // Jump target computation
  //----------------------------------------------------------------------

  logic [31:0] jump_target;

  always_comb begin
    if( !oldest_ctrl_inst.is_brx ) begin
      case( oldest_ctrl_inst.jal )
        2'd1:    jump_target = oldest_ctrl_inst.pc
                              + oldest_ctrl_inst.imm;
        2'd2:    jump_target = (oldest_ctrl_inst_jump_base
                              + oldest_ctrl_inst.imm)
                              & 32'hFFFFFFFE;
        default: jump_target = '0;
      endcase
    end else begin
      jump_target = '0;
    end
  end

  //----------------------------------------------------------------------
  // Combinational ctrl_flow notification
  //----------------------------------------------------------------------

  logic is_jump;
  logic is_jal;
  logic is_jal_predicted;

  assign is_jump          = oldest_ctrl_inst.found
                          & !oldest_ctrl_inst.is_brx
                          & oldest_ctrl_inst_dispatch_go;
  assign is_jal           = (oldest_ctrl_inst.jal == 2'd1);
  assign is_jal_predicted = is_jal & oldest_ctrl_inst.predicted_taken;

  // Redirect for unpredicted JAL or any JALR; predicted JAL skips redirect
  assign ctrl_flow_pub.redirect_val  = is_jump & !is_jal_predicted;

  // BP update for JAL only (not JALR)
  assign ctrl_flow_pub.bp_update_val = is_jump & is_jal;

  assign ctrl_flow_pub.pc            = oldest_ctrl_inst.pc;
  assign ctrl_flow_pub.target        = jump_target;
  assign ctrl_flow_pub.taken         = 1'b1;
  assign ctrl_flow_pub.seq_num       = oldest_ctrl_inst.seq_num;

endmodule

`endif // HW_DECODEISSUE_DIUCTRLFLOWPUBLISHER_V
