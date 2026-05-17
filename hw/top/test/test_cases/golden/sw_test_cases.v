//========================================================================
// sw_test_cases.v
//========================================================================
// Adapted from Cornell's ECE 2300

//------------------------------------------------------------------------
// test_case_golden_sw_1_regs
//------------------------------------------------------------------------

task test_case_golden_sw_1_regs();
  h.t.test_case_begin( "test_case_golden_sw_1_regs" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 0x100" );
  h.asm( 'h204, "addi x2,  x0, 0x104" );
  h.asm( 'h208, "addi x3,  x0, 0x108" );
  h.asm( 'h20c, "addi x4,  x0, 0x10c" );

  h.asm( 'h210, "addi x5,  x0, 10" );
  h.asm( 'h214, "addi x6,  x0, 11" );
  h.asm( 'h218, "addi x7,  x0, 12" );
  h.asm( 'h21c, "addi x8,  x0, 13" );

  h.asm( 'h220, "sw   x5, 0(x1)"     );
  h.asm( 'h224, "sw   x6, 0(x2)"     );
  h.asm( 'h228, "sw   x7, 0(x3)"     );
  h.asm( 'h22c, "sw   x8, 0(x4)"     );

  h.asm( 'h230, "lw   x5, 0(x1)"     );
  h.asm( 'h234, "lw   x6, 0(x2)"     );
  h.asm( 'h238, "lw   x7, 0(x3)"     );
  h.asm( 'h23c, "lw   x8, 0(x4)"     );

  h.asm( 'h240, "addi x28, x0, 0x110" );
  h.asm( 'h244, "addi x29, x0, 0x114" );
  h.asm( 'h248, "addi x30, x0, 0x118" );
  h.asm( 'h24c, "addi x31, x0, 0x11c" );

  h.asm( 'h250, "addi x5,  x0, 14" );
  h.asm( 'h254, "addi x6,  x0, 15" );
  h.asm( 'h258, "addi x7,  x0, 16" );
  h.asm( 'h25c, "addi x8,  x0, 17" );

  h.asm( 'h260, "sw   x5, 0(x28)"    );
  h.asm( 'h264, "sw   x6, 0(x29)"    );
  h.asm( 'h268, "sw   x7, 0(x30)"    );
  h.asm( 'h26c, "sw   x8, 0(x31)"    );

  h.asm( 'h270, "lw   x5, 0(x28)"    );
  h.asm( 'h274, "lw   x6, 0(x29)"    );
  h.asm( 'h278, "lw   x7, 0(x30)"    );
  h.asm( 'h27c, "lw   x8, 0(x31)"    );

  // Write h.data into memory

  h.data( 'h100, 'h0101_0101 );
  h.data( 'h104, 'h0202_0202 );
  h.data( 'h108, 'h0303_0303 );
  h.data( 'h10c, 'h0404_0404 );

  h.data( 'h110, 'h0505_0505 );
  h.data( 'h114, 'h0606_0606 );
  h.data( 'h118, 'h0707_0707 );
  h.data( 'h11c, 'h0808_0808 );

  h.check_traces();

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_golden_sw_2_mix
//------------------------------------------------------------------------

task test_case_golden_sw_2_mix();
  h.t.test_case_begin( "test_case_golden_sw_2_mix" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 0x100" );
  h.asm( 'h204, "addi x2,  x0, 0x110" );
  h.asm( 'h208, "addi x3,  x0, 0x120" );
  h.asm( 'h20c, "addi x4,  x0, 0"     );

  h.asm( 'h210, "lw   x5,  0(x1)"     );
  h.asm( 'h214, "lw   x6,  0(x2)"     );
  h.asm( 'h218, "mul  x7,  x5, x6"    );
  h.asm( 'h21c, "add  x4,  x4, x7"    );
  h.asm( 'h220, "sw   x4,  0(x3)"     );
  h.asm( 'h224, "addi x1,  x1, 4"     );
  h.asm( 'h228, "addi x2,  x2, 4"     );
  h.asm( 'h22c, "addi x3,  x3, 4"     );

  h.asm( 'h230, "lw   x5,  0(x1)"     );
  h.asm( 'h234, "lw   x6,  0(x2)"     );
  h.asm( 'h238, "mul  x7,  x5, x6"    );
  h.asm( 'h23c, "add  x4,  x4, x7"    );
  h.asm( 'h240, "sw   x4,  0(x3)"     );
  h.asm( 'h244, "addi x1,  x1, 4"     );
  h.asm( 'h248, "addi x2,  x2, 4"     );
  h.asm( 'h24c, "addi x3,  x3, 4"     );

  h.asm( 'h250, "lw   x5,  0(x1)"     );
  h.asm( 'h254, "lw   x6,  0(x2)"     );
  h.asm( 'h258, "mul  x7,  x5, x6"    );
  h.asm( 'h25c, "add  x4,  x4, x7"    );
  h.asm( 'h260, "sw   x4,  0(x3)"     );
  h.asm( 'h264, "addi x1,  x1, 4"     );
  h.asm( 'h268, "addi x2,  x2, 4"     );
  h.asm( 'h26c, "addi x3,  x3, 4"     );

  h.asm( 'h270, "addi x1,  x0, 0x120" );
  h.asm( 'h274, "lw   x2,  0(x1)"     );
  h.asm( 'h278, "lw   x3,  4(x1)"     );
  h.asm( 'h27c, "lw   x4,  8(x1)"     );

  // Write h.data into memory

  h.data( 'h100, 1 );
  h.data( 'h104, 2 );
  h.data( 'h108, 3 );

  h.data( 'h110, 5 );
  h.data( 'h114, 6 );
  h.data( 'h118, 7 );

  h.data( 'h120, 0 );
  h.data( 'h124, 0 );
  h.data( 'h128, 0 );

  h.check_traces();

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_golden_sw_tests
//------------------------------------------------------------------------

task run_golden_sw_tests();
  test_case_golden_sw_1_regs();
  test_case_golden_sw_2_mix();
endtask
