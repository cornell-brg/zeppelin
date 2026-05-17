//========================================================================
// assemble.v
//========================================================================
// An include to access the 32b assembly function

`ifndef ASM_ASSEMBLE_V
`define ASM_ASSEMBLE_V

import "DPI-C" function bit [31:0] assemble( string assembly, bit [31:0] pc );

`endif // ASM_ASSEMBLE_V
