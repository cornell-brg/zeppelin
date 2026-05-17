//========================================================================
// ImmGen.v
//========================================================================
// A RISC-V immediate generator

`ifndef HW_DECODE_IMMGEN_V
`define HW_DECODE_IMMGEN_V

`include "defs/ISA.v"

import ISA::*;

module ImmGen (
  input  logic [31:0] inst,
  input  rv_imm_type  imm_sel,
  output logic [31:0] imm
);

  always_comb begin
    case ( imm_sel )
      IMM_I:   imm = { {21{inst[31]}}, inst[30:20] };
      IMM_S:   imm = { {21{inst[31]}}, inst[30:25], inst[11:7] };
      IMM_B:   imm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
      IMM_U:   imm = { inst[31:12], 12'b0 };
      IMM_J:   imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
      default: imm = '0;
    endcase
  end

  logic [6:0] unused_inst;
  assign unused_inst = inst[6:0];

endmodule

`endif // HW_DECODE_IMMGEN_V
