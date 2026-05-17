//========================================================================
// lw_test_cases.v
//========================================================================
// Adapted from Cornell's ECE 2300

//------------------------------------------------------------------------
// test_case_directed_lw_1_basic
//------------------------------------------------------------------------

task test_case_directed_lw_1_basic();
  h.t.test_case_begin( "test_case_directed_lw_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 0x100" );
  h.asm( 'h204, "lw   x2, 0(x1)"     );

  // Write h.data into memory

  h.data( 'h100, 'hdead_beef );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_0100, 1 ); // addi x1, x0, 0x100
  h.check_trace( 'h204, 2, 'hdead_beef, 1 ); // lw   x2, 0(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_lw_2_x0
//------------------------------------------------------------------------

task test_case_directed_lw_2_x0();
  h.t.test_case_begin( "test_case_directed_lw_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 0x100" );
  h.asm( 'h204, "lw   x0, 0(x1)"     );
  h.asm( 'h208, "lw   x0, 0(x0)"     );

  // Write h.data into memory

  h.data( 'h100, 'hdead_beef );

  // Check each executed instruction

  h.check_trace( 'h200, 1,  'h0000_0100, 1 ); // addi x1, x0, 0x100
  h.check_trace( 'h204, 'x, 'x,          0 ); // lw   x0, 0(x1)
  h.check_trace( 'h208, 'x, 'x,          0 ); // lw   x0, 0(x0)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_lw_3_offset_pos
//------------------------------------------------------------------------

task test_case_directed_lw_3_offset_pos();
  h.t.test_case_begin( "test_case_directed_lw_3_offset_pos" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 0x100" );
  h.asm( 'h204, "lw   x2,  0(x1)"     );
  h.asm( 'h208, "lw   x3,  4(x1)"     );
  h.asm( 'h20c, "lw   x4,  8(x1)"     );
  h.asm( 'h210, "lw   x5,  12(x1)"    );

  // Write h.data into memory

  h.data( 'h100, 'h0000_2000 );
  h.data( 'h104, 'h0000_2004 );
  h.data( 'h108, 'h0000_2008 );
  h.data( 'h10c, 'h0000_200c );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_0100, 1 ); // addi x1, x0, 0x100
  h.check_trace( 'h204, 2, 'h0000_2000, 1 ); // lw   x2, 0(x1)
  h.check_trace( 'h208, 3, 'h0000_2004, 1 ); // lw   x3, 4(x1)
  h.check_trace( 'h20c, 4, 'h0000_2008, 1 ); // lw   x4, 8(x1)
  h.check_trace( 'h210, 5, 'h0000_200c, 1 ); // lw   x5, 12(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_lw_4_offset_neg
//------------------------------------------------------------------------

task test_case_directed_lw_4_offset_neg();
  h.t.test_case_begin( "test_case_directed_lw_4_offset_neg" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0, 0x10c" );
  h.asm( 'h204, "lw   x2,  0(x1)"     );
  h.asm( 'h208, "lw   x3,  -4(x1)"    );
  h.asm( 'h20c, "lw   x4,  -8(x1)"    );
  h.asm( 'h210, "lw   x5,  -12(x1)"   );

  // Write h.data into memory

  h.data( 'h100, 'h0000_2000 );
  h.data( 'h104, 'h0000_2004 );
  h.data( 'h108, 'h0000_2008 );
  h.data( 'h10c, 'h0000_200c );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_010c, 1 ); // addi x1, x0, 0x100
  h.check_trace( 'h204, 2, 'h0000_200c, 1 ); // lw   x2, 0(x1)
  h.check_trace( 'h208, 3, 'h0000_2008, 1 ); // lw   x3, -4(x1)
  h.check_trace( 'h20c, 4, 'h0000_2004, 1 ); // lw   x4, -8(x1)
  h.check_trace( 'h210, 5, 'h0000_2000, 1 ); // lw   x5, -12(x1)

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_lw_tests
//------------------------------------------------------------------------

task run_directed_lw_tests();
  test_case_directed_lw_1_basic();
  test_case_directed_lw_2_x0();
  test_case_directed_lw_3_offset_pos();
  test_case_directed_lw_4_offset_neg();
endtask
