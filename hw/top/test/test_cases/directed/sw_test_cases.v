//========================================================================
// sw_test_cases.v
//========================================================================
// Adapted from Cornell's ECE 2300

//------------------------------------------------------------------------
// test_case_directed_sw_1_basic
//------------------------------------------------------------------------

task test_case_directed_sw_1_basic();
  h.t.test_case_begin( "test_case_directed_sw_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 0x100" );
  h.asm( 'h204, "addi x2, x0, 0x42"  );
  h.asm( 'h208, "sw   x2, 0(x1)"     );
  h.asm( 'h20c, "lw   x3, 0(x1)"     );

  // Check each executed instruction

  h.check_trace( 'h200, 1,  'h0000_0100, 1 ); // addi x1, x0, 0x100
  h.check_trace( 'h204, 2,  'h0000_0042, 1 ); // addi x2, x0, 0x42
  h.check_trace( 'h208, 'x, 'x,          0 ); // sw   x2, 0(x1)
  h.check_trace( 'h20c, 3,  'h0000_0042, 1 ); // lw   x3, 0(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_sw_2_x0
//------------------------------------------------------------------------

task test_case_directed_sw_2_x0();
  h.t.test_case_begin( "test_case_directed_sw_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 0x100" );
  h.asm( 'h204, "sw   x0, 0(x1)"     );
  h.asm( 'h208, "lw   x2, 0(x1)"     );

  // Write h.data into memory

  h.data( 'h100, 32'hdead_beef );

  // Check each executed instruction

  h.check_trace( 'h200, 1,  'h0000_0100, 1 ); // addi x1, x0, 0x100
  h.check_trace( 'h204, 'x, 'x,          0 ); // sw   x0, 0(x1)
  h.check_trace( 'h208, 2,  'h0000_0000, 1 ); // lw   x2, 0(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_sw_3_offset_pos
//------------------------------------------------------------------------

task test_case_directed_sw_3_offset_pos();
  h.t.test_case_begin( "test_case_directed_sw_3_offset_pos" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 0x100" );

  h.asm( 'h204, "addi x2,  x0, 20"    );
  h.asm( 'h208, "addi x3,  x0, 21"    );
  h.asm( 'h20c, "addi x4,  x0, 22"    );
  h.asm( 'h210, "addi x5,  x0, 23"    );

  h.asm( 'h214, "sw   x2,  0(x1)"     );
  h.asm( 'h218, "sw   x3,  4(x1)"     );
  h.asm( 'h21c, "sw   x4,  8(x1)"     );
  h.asm( 'h220, "sw   x5,  12(x1)"    );

  h.asm( 'h224, "lw   x7,  0(x1)"     );
  h.asm( 'h228, "lw   x8,  4(x1)"     );
  h.asm( 'h22c, "lw   x9,  8(x1)"     );
  h.asm( 'h230, "lw   x10, 12(x1)"    );

  // Write h.data into memory

  h.data( 'h100, 'hdead_beef );
  h.data( 'h104, 'hdead_beef );
  h.data( 'h108, 'hdead_beef );
  h.data( 'h10c, 'hdead_beef );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h100, 1 ); // addi x1,  x0, 0x100

  h.check_trace( 'h204, 2,    20, 1 ); // addi x2,  x0, 20
  h.check_trace( 'h208, 3,    21, 1 ); // addi x3,  x0, 21
  h.check_trace( 'h20c, 4,    22, 1 ); // addi x4,  x0, 22
  h.check_trace( 'h210, 5,    23, 1 ); // addi x5,  x0, 23

  h.check_trace( 'h214, 'x,   'x, 0 ); // sw   x2,  0(x1)
  h.check_trace( 'h218, 'x,   'x, 0 ); // sw   x3,  4(x1)
  h.check_trace( 'h21c, 'x,   'x, 0 ); // sw   x4,  8(x1)
  h.check_trace( 'h220, 'x,   'x, 0 ); // sw   x5,  12(x1)

  h.check_trace( 'h224, 7,    20, 1 ); // lw   x7,  0(x1)
  h.check_trace( 'h228, 8,    21, 1 ); // lw   x8,  4(x1)
  h.check_trace( 'h22c, 9,    22, 1 ); // lw   x9,  8(x1)
  h.check_trace( 'h230, 10,   23, 1 ); // lw   x10, 12(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_sw_4_offset_neg
//------------------------------------------------------------------------

task test_case_directed_sw_4_offset_neg();
  h.t.test_case_begin( "test_case_directed_sw_4_offset_neg" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 0x10c" );

  h.asm( 'h204, "addi x2,  x0, 20"    );
  h.asm( 'h208, "addi x3,  x0, 21"    );
  h.asm( 'h20c, "addi x4,  x0, 22"    );
  h.asm( 'h210, "addi x5,  x0, 23"    );

  h.asm( 'h214, "sw   x2,  0(x1)"     );
  h.asm( 'h218, "sw   x3,  -4(x1)"     );
  h.asm( 'h21c, "sw   x4,  -8(x1)"     );
  h.asm( 'h220, "sw   x5,  -12(x1)"    );

  h.asm( 'h224, "addi x1,  x0, 0x100" );

  h.asm( 'h228, "lw   x7,  0(x1)"     );
  h.asm( 'h22c, "lw   x8,  4(x1)"     );
  h.asm( 'h230, "lw   x9,  8(x1)"     );
  h.asm( 'h234, "lw   x10, 12(x1)"    );

  // Write h.data into memory

  h.data( 'h100, 'hdead_beef );
  h.data( 'h104, 'hdead_beef );
  h.data( 'h108, 'hdead_beef );
  h.data( 'h10c, 'hdead_beef );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h10c, 1 ); // addi x1,  x0, 0x10c

  h.check_trace( 'h204, 2,    20, 1 ); // addi x2,  x0, 20
  h.check_trace( 'h208, 3,    21, 1 ); // addi x3,  x0, 21
  h.check_trace( 'h20c, 4,    22, 1 ); // addi x4,  x0, 22
  h.check_trace( 'h210, 5,    23, 1 ); // addi x5,  x0, 23

  h.check_trace( 'h214, 'x,   'x, 0 ); // sw   x2,  0(x1)
  h.check_trace( 'h218, 'x,   'x, 0 ); // sw   x3,  -4(x1)
  h.check_trace( 'h21c, 'x,   'x, 0 ); // sw   x4,  -8(x1)
  h.check_trace( 'h220, 'x,   'x, 0 ); // sw   x5,  -12(x1)

  h.check_trace( 'h224, 1, 'h100, 1 ); // addi x1,  x0, 0x100

  h.check_trace( 'h228, 7,    23, 1 ); // lw   x7,  0(x1)
  h.check_trace( 'h22c, 8,    22, 1 ); // lw   x8,  4(x1)
  h.check_trace( 'h230, 9,    21, 1 ); // lw   x9,  8(x1)
  h.check_trace( 'h234, 10,   20, 1 ); // lw   x10, 12(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_sw_tests
//------------------------------------------------------------------------

task run_directed_sw_tests();
  test_case_directed_sw_1_basic();
  test_case_directed_sw_2_x0();
  test_case_directed_sw_3_offset_pos();
  test_case_directed_sw_4_offset_neg();
endtask
