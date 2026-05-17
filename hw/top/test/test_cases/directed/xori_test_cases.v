//========================================================================
// xori_test_cases
//========================================================================

//------------------------------------------------------------------------
// test_case_directed_xori_1_basic
//------------------------------------------------------------------------

task test_case_directed_xori_1_basic();
  h.t.test_case_begin( "test_case_directed_xori_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 5" );
  h.asm( 'h204, "xori x2, x1, 3" );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_0005, 1 ); // addi x1, x0, 5
  h.check_trace( 'h204, 2, 'h0000_0006, 1 ); // xori x3, x1, x2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_xori_2_x0
//------------------------------------------------------------------------

task test_case_directed_xori_2_x0();
  h.t.test_case_begin( "test_case_directed_xori_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x2, x0, 2"  );
  h.asm( 'h204, "xori x0, x0, 0" );
  h.asm( 'h208, "xori x0, x0, 1" );
  h.asm( 'h20c, "xori x0, x2, 0" );
  h.asm( 'h210, "xori x3, x0, 1" );
  h.asm( 'h214, "xori x4, x2, 0" );

  // Check each executed instruction

  h.check_trace( 'h200,  2, 'h02, 1 ); // addi x2, x0, 2
  h.check_trace( 'h204, 'x, 'x,   0 ); // xori x0, x0, 0
  h.check_trace( 'h208, 'x, 'x,   0 ); // xori x0, x0, 1
  h.check_trace( 'h20c, 'x, 'x,   0 ); // xori x0, x2, 0
  h.check_trace( 'h210,  3, 'h01, 1 ); // xori x3, x0, 1
  h.check_trace( 'h214,  4, 'h02, 1 ); // xori x4, x2, 0


  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_xori_3_extreme
//------------------------------------------------------------------------

task test_case_directed_xori_3_extreme();
  h.t.test_case_begin( "test_case_directed_xori_3_extreme" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0,  0xfff" );
  h.asm( 'h204, "addi x2,  x0,  0x7ff" );
  h.asm( 'h208, "addi x3,  x0,  1"     );

  h.asm( 'h20c, "xori x4,  x1,  0x7ff" );
  h.asm( 'h210, "xori x5,  x2,  1"     );
  h.asm( 'h214, "xori x6,  x3,  0xfff" );
  h.asm( 'h218, "xori x7,  x1,  0"     );
  h.asm( 'h21c, "xori x8,  x1,  0xfff" );
  h.asm( 'h220, "xori x9,  x0,  0"     );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'hffff_ffff,    1 ); // addi x1,  x0,  0xfff
  h.check_trace( 'h204, 2, 'h0000_07ff,    1 ); // addi x2,  x0,  0x7ff
  h.check_trace( 'h208, 3, 'h0000_0001,    1 ); // addi x3,  x0,  1

  h.check_trace( 'h20c, 4, 'hffff_f800,    1 ); // xori x4,  x1,  0x7ff
  h.check_trace( 'h210, 5, 'h0000_07fe,    1 ); // xori x5,  x2,  1
  h.check_trace( 'h214, 6, 'hffff_fffe,    1 ); // xori x6,  x3,  0xfff
  h.check_trace( 'h218, 7, 'hffff_ffff,    1 ); // xori x7,  x1,  0
  h.check_trace( 'h21c, 8, 'h0000_0000,    1 ); // xori x8,  x1,  0xfff
  h.check_trace( 'h220, 9, 'h0000_0000,    1 ); // xori x9,  x0,  0

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_xori_tests
//------------------------------------------------------------------------

task run_directed_xori_tests();
  test_case_directed_xori_1_basic();
  test_case_directed_xori_2_x0();
  test_case_directed_xori_3_extreme();
endtask
