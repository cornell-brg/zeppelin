//========================================================================
// jalr_test_cases.v
//========================================================================
// Adapted from Cornell's ECE 2300 (jr)

//------------------------------------------------------------------------
// test_case_directed_jalr_1_basic
//------------------------------------------------------------------------

task test_case_directed_jalr_1_basic();
  h.t.test_case_begin( "test_case_directed_jalr_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 0x20c" );
  h.asm( 'h204, "jalr x2, x1, 0" );
  h.asm( 'h208, "addi x1, x0, 2" );

  h.asm( 'h20c, "addi x1, x0, 0x200" );
  h.asm( 'h210, "jalr x2, x1, 0x018" );
  h.asm( 'h214, "addi x1, x0, 3" );
  h.asm( 'h218, "addi x1, x0, 4" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h0000_020c, 1 ); // addi x1, x0, 0x200
  h.check_trace( 'h204,  2, 'h0000_0208, 1 ); // jal  x2, x1, 0x00c
  h.check_trace( 'h20c,  1, 'h0000_0200, 1 ); // addi x1, x0, 0x200
  h.check_trace( 'h210,  2, 'h0000_0214, 1 ); // jal  x2, x1, 0x018
  h.check_trace( 'h218,  1, 'h0000_0004, 1 ); // addi x1, x0, 4

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_2_x0
//------------------------------------------------------------------------

task test_case_directed_jalr_2_x0();
  h.t.test_case_begin( "test_case_directed_jalr_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jalr x0, x0, 0x208" );
  h.asm( 'h204, "addi x1, x0, 2" );
  h.asm( 'h208, "addi x1, x0, 7" );

  // Check each executed instruction

  h.check_trace( 'h200, 'x, 'x,          0 ); // jal  x2, x1, 0x00c
  h.check_trace( 'h208,  1, 'h0000_0007, 1 ); // addi x1, x0, 7

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_3_chain
//------------------------------------------------------------------------

task test_case_directed_jalr_3_chain();
  h.t.test_case_begin( "test_case_directed_jalr_3_chain" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 0x014" );
  h.asm( 'h204, "addi x2, x0, 0x01c" );
  h.asm( 'h208, "addi x3, x0, 0x024" );

  h.asm( 'h20c, "jalr x1, x1, 0x200" );
  h.asm( 'h210, "addi x4, x0, 1"     );
  h.asm( 'h214, "jalr x2, x2, 0x200" );
  h.asm( 'h218, "addi x5, x0, 2"     );
  h.asm( 'h21c, "jalr x3, x3, 0x200" );
  h.asm( 'h220, "addi x6, x0, 3"     );
  h.asm( 'h224, "addi x7, x0, 4"     );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h014, 1 ); // addi x1, x0, 0x014
  h.check_trace( 'h204, 2, 'h01c, 1 ); // addi x2, x0, 0x01c
  h.check_trace( 'h208, 3, 'h024, 1 ); // addi x3, x0, 0x024

  h.check_trace( 'h20c, 1, 'h210, 1 ); // jalr x1, x1, 0x200
  h.check_trace( 'h214, 2, 'h218, 1 ); // jalr x2, x2, 0x200
  h.check_trace( 'h21c, 3, 'h220, 1 ); // jalr x3, x3, 0x200
  h.check_trace( 'h224, 7,     4, 1 ); // addi x7, x0, 4

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_4_forward
//------------------------------------------------------------------------

task test_case_directed_jalr_4_forward();
  h.t.test_case_begin( "test_case_directed_jalr_4_forward" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jalr x1,  x0,  0x208" );
  h.asm( 'h204, "addi x2,  x0,  1"     );
  h.asm( 'h208, "addi x3,  x0,  2"     );

  h.asm( 'h20c, "jalr x4,  x0,  0x218" );
  h.asm( 'h210, "addi x5,  x0,  3"     );
  h.asm( 'h214, "addi x6,  x0,  4"     );
  h.asm( 'h218, "addi x7,  x0,  5"     );

  h.asm( 'h21c, "jalr x8,  x0,  0x22c" );
  h.asm( 'h220, "addi x9,  x0,  6"     );
  h.asm( 'h224, "addi x10, x0,  7"     );
  h.asm( 'h228, "addi x11, x0,  8"     );
  h.asm( 'h22c, "addi x12, x0,  9"     );

  h.asm( 'h230, "jalr x13, x0, 0x244"  );
  h.asm( 'h234, "addi x14, x0, 10"     );
  h.asm( 'h238, "addi x15, x0, 11"     );
  h.asm( 'h23c, "addi x16, x0, 12"     );
  h.asm( 'h240, "addi x17, x0, 13"     );
  h.asm( 'h244, "addi x18, x0, 14"     );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h204, 1 ); // jalr x1,  x0,  0x208
  h.check_trace( 'h208,  3,     2, 1 ); // addi x3,  x0,  2

  h.check_trace( 'h20c,  4, 'h210, 1 ); // jalr x4,  x0,  0x218
  h.check_trace( 'h218,  7,     5, 1 ); // addi x7,  x0,  5

  h.check_trace( 'h21c,  8, 'h220, 1 ); // jalr x8,  x0,  0x22c
  h.check_trace( 'h22c, 12,     9, 1 ); // addi x12, x0,  9

  h.check_trace( 'h230, 13, 'h234, 1 ); // jalr x13, x0, 0x244
  h.check_trace( 'h244, 18,    14, 1 ); // addi x18, x0, 14

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_5_backward
//------------------------------------------------------------------------

task test_case_directed_jalr_5_backward();
  h.t.test_case_begin( "test_case_directed_jalr_5_backward" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jalr x1,  x0, 0x234"  ); // --------.
  h.asm( 'h204, "addi x2,  x0, 1"      ); // <-.     |
  h.asm( 'h208, "addi x3,  x0, 2"      ); //   |     |
  h.asm( 'h20c, "addi x4,  x0, 3"      ); //   |     |
  h.asm( 'h210, "addi x5,  x0, 4"      ); //   |     |
  h.asm( 'h214, "addi x6,  x0, 5"      ); //   |     |
  h.asm( 'h218, "addi x7,  x0, 6"      ); // <-+--.  |
  h.asm( 'h21c, "jalr x8,  x0, 0x204"  ); // --'  |  |
  h.asm( 'h220, "addi x9,  x0, 7"      ); //      |  |
  h.asm( 'h224, "addi x10, x0, 8"      ); //      |  |
  h.asm( 'h228, "addi x11, x0, 9"      ); // <-.  |  |
  h.asm( 'h22c, "jalr x12, x0, 0x218"  ); // --+--'  |
  h.asm( 'h230, "addi x13, x0, 10"     ); //   |     |
  h.asm( 'h234, "addi x14, x0, 11"     ); // <-+-----'
  h.asm( 'h238, "jalr x15, x0, 0x228"  ); // --'

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h204, 1 ); // jalr x1,  x0, 0x038
  h.check_trace( 'h234, 14,    11, 1 ); // addi x14, x0, 11
  h.check_trace( 'h238, 15, 'h23c, 1 ); // jalr x15, x0, 0x028
  h.check_trace( 'h228, 11,     9, 1 ); // addi x11, x0, 9
  h.check_trace( 'h22c, 12, 'h230, 1 ); // jalr x12, x0, 0x018
  h.check_trace( 'h218,  7,     6, 1 ); // addi x7,  x0, 6
  h.check_trace( 'h21c,  8, 'h220, 1 ); // jalr x8,  x0, 0x004
  h.check_trace( 'h204,  2,     1, 1 ); // addi x2,  x0, 1
  h.check_trace( 'h208,  3,     2, 1 ); // addi x3,  x0, 2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_6_loop
//------------------------------------------------------------------------

task test_case_directed_jalr_6_loop();
  h.t.test_case_begin( "test_case_directed_jalr_6_loop" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 1"     ); // <-.
  h.asm( 'h204, "addi x2,  x0, 2"     ); //   |
  h.asm( 'h208, "addi x3,  x0, 3"     ); //   |
  h.asm( 'h20c, "jalr x4,  x0, 0x200" ); // --'

  // Check each executed instruction

  h.check_trace( 'h200,  1,     1, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2,     2, 1 ); // addi x2,  x0, 2
  h.check_trace( 'h208,  3,     3, 1 ); // addi x3,  x0, 3
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jalr x4,  x0, 0x200
  h.check_trace( 'h200,  1,     1, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2,     2, 1 ); // addi x2,  x0, 2
  h.check_trace( 'h208,  3,     3, 1 ); // addi x3,  x0, 3
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jalr x4,  x0, 0x200
  h.check_trace( 'h200,  1,     1, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2,     2, 1 ); // addi x2,  x0, 2
  h.check_trace( 'h208,  3,     3, 1 ); // addi x3,  x0, 3
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jalr x4,  x0, 0x200

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_7_loop_self
//------------------------------------------------------------------------

task test_case_directed_jalr_7_loop_self();
  h.t.test_case_begin( "test_case_directed_jalr_7_loop_self" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x0, x0, 0"     );
  h.asm( 'h204, "addi x0, x0, 0"     );
  h.asm( 'h208, "jalr x1, x0, 0x208" );

  // Check each executed instruction

  h.check_trace( 'h200, 'x,    'x, 0 ); // addi x0, x0, 0
  h.check_trace( 'h204, 'x,    'x, 0 ); // addi x0, x0, 0
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jalr x1, x0, 0x208
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jalr x1, x0, 0x208
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jalr x1, x0, 0x208
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jalr x1, x0, 0x208

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_8_return
//------------------------------------------------------------------------

task test_case_directed_jalr_8_return();
  h.t.test_case_begin( "test_case_directed_jalr_8_return" );
  if( !h.t.run_test ) return;
  fl_reset();

  h.asm( 'h200, "addi x1, x0, 0x200" );
  h.asm( 'h204, "jalr x2, x1, 0x014" );
  h.asm( 'h208, "jalr x3, x1, 0x018" );
  h.asm( 'h20c, "jalr x4, x1, 0x01c" );
  h.asm( 'h210, "addi x5, x0, 5"     );

  h.asm( 'h214, "jalr x0, x2, 0" );
  h.asm( 'h218, "jalr x0, x3, 0" );
  h.asm( 'h21c, "jalr x0, x4, 0" );

  h.check_trace( 'h200,  1, 'h200, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2, 'h208, 1 ); // jalr x2, x1, 0x014
  h.check_trace( 'h214, 'x, 'x,    0 ); // jalr x0, x2, 0
  h.check_trace( 'h208,  3, 'h20c, 1 ); // jalr x3, x1, 0x018
  h.check_trace( 'h218, 'x, 'x,    0 ); // jalr x0, x3, 0
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jalr x4, x1, 0x01c
  h.check_trace( 'h21c, 'x, 'x,    0 ); // jalr x0, x4, 0
  h.check_trace( 'h210,  5,  5,    1 ); // addi x1,  x0, 1

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jalr_9_mix
//------------------------------------------------------------------------

task test_case_directed_jalr_9_mix();
  h.t.test_case_begin( "test_case_directed_jalr_9_mix" );
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
  h.asm( 'h230, "jalr x0,  x0, 0x210" );

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

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h100, 1 ); // addi x1,  x0, 0x100
  h.check_trace( 'h204, 2, 'h110, 1 ); // addi x2,  x0, 0x110
  h.check_trace( 'h208, 3, 'h120, 1 ); // addi x3,  x0, 0x120
  h.check_trace( 'h20c, 4,     0, 1 ); // addi x4,  x0, 0

  h.check_trace( 'h210,  5,     1, 1 ); // lw   x5,  0(x1)
  h.check_trace( 'h214,  6,     5, 1 ); // lw   x6,  0(x2)
  h.check_trace( 'h218,  7,     5, 1 ); // mul  x7,  x5, x6
  h.check_trace( 'h21c,  4,     5, 1 ); // add  x4,  x4, x7
  h.check_trace( 'h220, 'x,    'x, 0 ); // sw   x4,  0(x3)
  h.check_trace( 'h224,  1, 'h104, 1 ); // addi x1,  x1, 4
  h.check_trace( 'h228,  2, 'h114, 1 ); // addi x2,  x2, 4
  h.check_trace( 'h22c,  3, 'h124, 1 ); // addi x3,  x3, 4
  h.check_trace( 'h230, 'x,    'x, 0 ); // jalr x0,  x0, 0x010
  
  h.check_trace( 'h210,  5,     2, 1 ); // lw   x5,  0(x1)
  h.check_trace( 'h214,  6,     6, 1 ); // lw   x6,  0(x2)
  h.check_trace( 'h218,  7,    12, 1 ); // mul  x7,  x5, x6
  h.check_trace( 'h21c,  4,    17, 1 ); // add  x4,  x4, x7
  h.check_trace( 'h220, 'x,    'x, 0 ); // sw   x4,  0(x3)
  h.check_trace( 'h224,  1, 'h108, 1 ); // addi x1,  x1, 4
  h.check_trace( 'h228,  2, 'h118, 1 ); // addi x2,  x2, 4
  h.check_trace( 'h22c,  3, 'h128, 1 ); // addi x3,  x3, 4
  h.check_trace( 'h230, 'x,    'x, 0 ); // jalr x0,  x0, 0x010

  h.check_trace( 'h210,  5,     3, 1 ); // lw   x5,  0(x1)
  h.check_trace( 'h214,  6,     7, 1 ); // lw   x6,  0(x2)
  h.check_trace( 'h218,  7,    21, 1 ); // mul  x7,  x5, x6
  h.check_trace( 'h21c,  4,    38, 1 ); // add  x4,  x4, x7
  h.check_trace( 'h220, 'x,    'x, 0 ); // sw   x4,  0(x3)
  h.check_trace( 'h224,  1, 'h10c, 1 ); // addi x1,  x1, 4
  h.check_trace( 'h228,  2, 'h11c, 1 ); // addi x2,  x2, 4
  h.check_trace( 'h22c,  3, 'h12c, 1 ); // addi x3,  x3, 4
  h.check_trace( 'h230, 'x,    'x, 0 ); // jalr x0,  x0, 0x010

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_jalr_tests
//------------------------------------------------------------------------

task run_directed_jalr_tests();
  test_case_directed_jalr_1_basic();
  test_case_directed_jalr_2_x0();
  test_case_directed_jalr_3_chain();
  test_case_directed_jalr_4_forward();
  test_case_directed_jalr_5_backward();
  test_case_directed_jalr_6_loop();
  test_case_directed_jalr_7_loop_self();
  test_case_directed_jalr_8_return();
  test_case_directed_jalr_9_mix();
endtask
