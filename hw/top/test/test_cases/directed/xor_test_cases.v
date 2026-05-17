//========================================================================
// xor_test_cases
//========================================================================

//------------------------------------------------------------------------
// test_case_directed_xor_1_basic
//------------------------------------------------------------------------

task test_case_directed_xor_1_basic();
  h.t.test_case_begin( "test_case_directed_xor_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 5"  );
  h.asm( 'h204, "addi x2, x0, 3"  );
  h.asm( 'h208, "xor  x3, x1, x2" );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_0005, 1 ); // addi x1, x0, 5
  h.check_trace( 'h204, 2, 'h0000_0003, 1 ); // addi x2, x0, 3
  h.check_trace( 'h208, 3, 'h0000_0006, 1 ); // xor  x3, x1, x2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_xor_2_x0
//------------------------------------------------------------------------

task test_case_directed_xor_2_x0();
  h.t.test_case_begin( "test_case_directed_xor_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 1"  );
  h.asm( 'h204, "addi x2, x0, 2"  );
  h.asm( 'h208, "xor  x0, x0, x0" );
  h.asm( 'h20c, "xor  x0, x0, x1" );
  h.asm( 'h210, "xor  x0, x2, x0" );
  h.asm( 'h214, "xor  x3, x0, x1" );
  h.asm( 'h218, "xor  x4, x2, x0" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h01, 1 ); // addi x1, x0, 1
  h.check_trace( 'h204,  2, 'h02, 1 ); // addi x2, x0, 2
  h.check_trace( 'h208, 'x, 'x,   0 ); // xor  x0, x0, x0
  h.check_trace( 'h20c, 'x, 'x,   0 ); // xor  x0, x0, x1
  h.check_trace( 'h210, 'x, 'x,   0 ); // xor  x0, x2, x0
  h.check_trace( 'h214,  3, 'h01, 1 ); // xor  x3, x0, x1
  h.check_trace( 'h218,  4, 'h02, 1 ); // xor  x4, x2, x0


  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_xor_3_extreme
//------------------------------------------------------------------------

task test_case_directed_xor_3_extreme();
  h.t.test_case_begin( "test_case_directed_xor_3_extreme" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0,  0xfff" );
  h.asm( 'h204, "addi x2,  x0,  0x7ff" );
  h.asm( 'h208, "addi x3,  x0,  1"     );

  h.asm( 'h20c, "xor  x4,  x1,  x2"   );
  h.asm( 'h210, "xor  x5,  x2,  x3"   );
  h.asm( 'h214, "xor  x6,  x3,  x1"   );
  h.asm( 'h218, "xor  x7,  x1,  x0"   );
  h.asm( 'h21c, "xor  x8,  x1,  x1"   );
  h.asm( 'h220, "xor  x9,  x0,  x0"   );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'hffff_ffff,    1 ); // addi x1,  x0,  0xfff
  h.check_trace( 'h204, 2, 'h0000_07ff,    1 ); // addi x2,  x0,  0x7ff
  h.check_trace( 'h208, 3, 'h0000_0001,    1 ); // addi x3,  x0,  1

  h.check_trace( 'h20c, 4, 'hffff_f800,    1 ); // xor  x4,  x1,  x2
  h.check_trace( 'h210, 5, 'h0000_07fe,    1 ); // xor  x5,  x2,  x3
  h.check_trace( 'h214, 6, 'hffff_fffe,    1 ); // xor  x6,  x3,  x1
  h.check_trace( 'h218, 7, 'hffff_ffff,    1 ); // xor  x7,  x1,  x0
  h.check_trace( 'h21c, 8, 'h0000_0000,    1 ); // xor  x8,  x1,  x1
  h.check_trace( 'h220, 9, 'h0000_0000,    1 ); // xor  x9,  x0,  x0

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_xor_tests
//------------------------------------------------------------------------

task run_directed_xor_tests();
  test_case_directed_xor_1_basic();
  test_case_directed_xor_2_x0();
  test_case_directed_xor_3_extreme();
endtask
