//========================================================================
// disassemble.v
//========================================================================
// An include to access the 32b disassembly function

`ifndef ASM_DISASSEMBLE32_V
`define ASM_DISASSEMBLE32_V

import "DPI-C" function string disassemble( bit [31:0] binary, bit [31:0] pc );

`endif // ASM_DISASSEMBLE_V
