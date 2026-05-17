//========================================================================
// jal_test_cases.v
//========================================================================
// Adapted from Cornell's ECE 2300

//------------------------------------------------------------------------
// test_case_directed_jal_1_basic
//------------------------------------------------------------------------

task test_case_directed_jal_1_basic();
  h.t.test_case_begin( "test_case_directed_jal_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 1" );
  h.asm( 'h204, "jal  x2, 0x20c" );
  h.asm( 'h208, "addi x1, x0, 2" );
  h.asm( 'h20c, "addi x1, x0, 3" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h0000_0001, 1 ); // addi x1, x0, 1
  h.check_trace( 'h204,  2, 'h0000_0208, 1 ); // jal  x2, 0x00c
  h.check_trace( 'h20c,  1, 'h0000_0003, 1 ); // addi x1, x0, 3

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_2_x0
//------------------------------------------------------------------------

task test_case_directed_jal_2_x0();
  h.t.test_case_begin( "test_case_directed_jal_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jal  x0, 0x208"   );
  h.asm( 'h204, "addi x1, x0, 1"   );
  h.asm( 'h208, "addi x2, x0, 2"   );

  // Check each executed instruction

  h.check_trace( 'h200, 'x,          'x, 0 ); // jal  x0, 0x008
  h.check_trace( 'h208,  2, 'h0000_0002, 1 ); // addi x2, x0, 2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_3_chain
//------------------------------------------------------------------------

task test_case_directed_jal_3_chain();
  h.t.test_case_begin( "test_case_directed_jal_3_chain" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jal  x1, 0x208" );
  h.asm( 'h204, "addi x2, x0, 1" );
  h.asm( 'h208, "jal  x3, 0x210" );
  h.asm( 'h20c, "addi x4, x0, 2" );
  h.asm( 'h210, "jal  x5, 0x218" );
  h.asm( 'h214, "addi x6, x0, 3" );
  h.asm( 'h218, "addi x7, x0, 4" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h204, 1 ); // jal  x1, 0x208
  h.check_trace( 'h208,  3, 'h20c, 1 ); // jal  x3, 0x210
  h.check_trace( 'h210,  5, 'h214, 1 ); // jal  x5, 0x218
  h.check_trace( 'h218,  7,     4, 1 ); // addi x7, x0, 4

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_4_forward
//------------------------------------------------------------------------

task test_case_directed_jal_4_forward();
  h.t.test_case_begin( "test_case_directed_jal_4_forward" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jal  x1,  0x208"  );
  h.asm( 'h204, "addi x2,  x0,  1" );
  h.asm( 'h208, "addi x3,  x0,  2" );

  h.asm( 'h20c, "jal  x4,  0x218"  );
  h.asm( 'h210, "addi x5,  x0,  3" );
  h.asm( 'h214, "addi x6,  x0,  4" );
  h.asm( 'h218, "addi x7,  x0,  5" );

  h.asm( 'h21c, "jal  x8,  0x22c" );
  h.asm( 'h220, "addi x9,  x0,  6" );
  h.asm( 'h224, "addi x10, x0,  7" );
  h.asm( 'h228, "addi x11, x0,  8" );
  h.asm( 'h22c, "addi x12, x0,  9" );

  h.asm( 'h230, "jal  x13, 0x244"  );
  h.asm( 'h234, "addi x14, x0, 10" );
  h.asm( 'h238, "addi x15, x0, 11" );
  h.asm( 'h23c, "addi x16, x0, 12" );
  h.asm( 'h240, "addi x17, x0, 13" );
  h.asm( 'h244, "addi x18, x0, 14" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h204, 1 ); // jal  x1,  0x208
  h.check_trace( 'h208,  3,     2, 1 ); // addi x3,  x0,  2

  h.check_trace( 'h20c,  4, 'h210, 1 ); // jal  x4,  0x218
  h.check_trace( 'h218,  7,     5, 1 ); // addi x7,  x0,  5

  h.check_trace( 'h21c,  8, 'h220, 1 ); // jal  x8,  0x22c
  h.check_trace( 'h22c, 12,     9, 1 ); // addi x12, x0,  9

  h.check_trace( 'h230, 13, 'h234, 1 ); // jal  x13, 0x244
  h.check_trace( 'h244, 18,    14, 1 ); // addi x18, x0, 14

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_5_backward
//------------------------------------------------------------------------

task test_case_directed_jal_5_backward();
  h.t.test_case_begin( "test_case_directed_jal_5_backward" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "jal  x1,  0x234"  ); // --------.
  h.asm( 'h204, "addi x2,  x0, 1"  ); // <-.     |
  h.asm( 'h208, "addi x3,  x0, 2"  ); //   |     |
  h.asm( 'h20c, "addi x4,  x0, 3"  ); //   |     |
  h.asm( 'h210, "addi x5,  x0, 4"  ); //   |     |
  h.asm( 'h214, "addi x6,  x0, 5"  ); //   |     |
  h.asm( 'h218, "addi x7,  x0, 6"  ); // <-+--.  |
  h.asm( 'h21c, "jal  x8,  0x204"  ); // --'  |  |
  h.asm( 'h220, "addi x9,  x0, 7"  ); //      |  |
  h.asm( 'h224, "addi x10, x0, 8"  ); //      |  |
  h.asm( 'h228, "addi x11, x0, 9"  ); // <-.  |  |
  h.asm( 'h22c, "jal  x12, 0x218"  ); // --+--'  |
  h.asm( 'h230, "addi x13, x0, 10" ); //   |     |
  h.asm( 'h234, "addi x14, x0, 11" ); // <-+-----'
  h.asm( 'h238, "jal  x15, 0x228"  ); // --'

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h204, 1 ); // jal  x1,  0x238
  h.check_trace( 'h234, 14,    11, 1 ); // addi x14, x0, 11
  h.check_trace( 'h238, 15, 'h23c, 1 ); // jal  x15, 0x228
  h.check_trace( 'h228, 11,     9, 1 ); // addi x11, x0, 9
  h.check_trace( 'h22c, 12, 'h230, 1 ); // jal  x12, 0x218
  h.check_trace( 'h218,  7,     6, 1 ); // addi x7,  x0, 6
  h.check_trace( 'h21c,  8, 'h220, 1 ); // jal  x8,  0x204
  h.check_trace( 'h204,  2,     1, 1 ); // addi x2,  x0, 1
  h.check_trace( 'h208,  3,     2, 1 ); // addi x3,  x0, 2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_6_loop
//------------------------------------------------------------------------

task test_case_directed_jal_6_loop();
  h.t.test_case_begin( "test_case_directed_jal_6_loop" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 1"  ); // <-.
  h.asm( 'h204, "addi x2,  x0, 2"  ); //   |
  h.asm( 'h208, "addi x3,  x0, 3"  ); //   |
  h.asm( 'h20c, "jal  x4,  0x200"  ); // --'

  // Check each executed instruction

  h.check_trace( 'h200,  1,     1, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2,     2, 1 ); // addi x2,  x0, 2
  h.check_trace( 'h208,  3,     3, 1 ); // addi x3,  x0, 3
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jal  x4,  0x200
  h.check_trace( 'h200,  1,     1, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2,     2, 1 ); // addi x2,  x0, 2
  h.check_trace( 'h208,  3,     3, 1 ); // addi x3,  x0, 3
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jal  x4,  0x200
  h.check_trace( 'h200,  1,     1, 1 ); // addi x1,  x0, 1
  h.check_trace( 'h204,  2,     2, 1 ); // addi x2,  x0, 2
  h.check_trace( 'h208,  3,     3, 1 ); // addi x3,  x0, 3
  h.check_trace( 'h20c,  4, 'h210, 1 ); // jal  x4,  0x200

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_7_loop_self
//------------------------------------------------------------------------

task test_case_directed_jal_7_loop_self();
  h.t.test_case_begin( "test_case_directed_jal_7_loop_self" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x0, x0, 0" );
  h.asm( 'h204, "addi x0, x0, 0" );
  h.asm( 'h208, "jal  x1, 0x208" );

  // Check each executed instruction

  h.check_trace( 'h200, 'x,    'x, 0 ); // addi x0, x0, 0
  h.check_trace( 'h204, 'x,    'x, 0 ); // addi x0, x0, 0
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jal x1, 0x208
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jal x1, 0x208
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jal x1, 0x208
  h.check_trace( 'h208,  1, 'h20c, 1 ); // jal x1, 0x208

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_jal_8_mix
//------------------------------------------------------------------------

task test_case_directed_jal_8_mix();
  h.t.test_case_begin( "test_case_directed_jal_8_mix" );
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
  h.asm( 'h230, "jal  x0,  0x210"     );

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
  h.check_trace( 'h230, 'x,    'x, 0 ); // jal  x0,  0x010
  
  h.check_trace( 'h210,  5,     2, 1 ); // lw   x5,  0(x1)
  h.check_trace( 'h214,  6,     6, 1 ); // lw   x6,  0(x2)
  h.check_trace( 'h218,  7,    12, 1 ); // mul  x7,  x5, x6
  h.check_trace( 'h21c,  4,    17, 1 ); // add  x4,  x4, x7
  h.check_trace( 'h220, 'x,    'x, 0 ); // sw   x4,  0(x3)
  h.check_trace( 'h224,  1, 'h108, 1 ); // addi x1,  x1, 4
  h.check_trace( 'h228,  2, 'h118, 1 ); // addi x2,  x2, 4
  h.check_trace( 'h22c,  3, 'h128, 1 ); // addi x3,  x3, 4
  h.check_trace( 'h230, 'x,    'x, 0 ); // jal  x0,  0x010

  h.check_trace( 'h210,  5,     3, 1 ); // lw   x5,  0(x1)
  h.check_trace( 'h214,  6,     7, 1 ); // lw   x6,  0(x2)
  h.check_trace( 'h218,  7,    21, 1 ); // mul  x7,  x5, x6
  h.check_trace( 'h21c,  4,    38, 1 ); // add  x4,  x4, x7
  h.check_trace( 'h220, 'x,    'x, 0 ); // sw   x4,  0(x3)
  h.check_trace( 'h224,  1, 'h10c, 1 ); // addi x1,  x1, 4
  h.check_trace( 'h228,  2, 'h11c, 1 ); // addi x2,  x2, 4
  h.check_trace( 'h22c,  3, 'h12c, 1 ); // addi x3,  x3, 4
  h.check_trace( 'h230, 'x,    'x, 0 ); // jal  x0,  0x010

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_jal_tests
//------------------------------------------------------------------------

task run_directed_jal_tests();
  test_case_directed_jal_1_basic();
  test_case_directed_jal_2_x0();
  test_case_directed_jal_3_chain();
  test_case_directed_jal_4_forward();
  test_case_directed_jal_5_backward();
  test_case_directed_jal_6_loop();
  test_case_directed_jal_7_loop_self();
  test_case_directed_jal_8_mix();
endtask
