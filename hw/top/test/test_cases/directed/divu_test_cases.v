//========================================================================
// divu_test_cases.v
//========================================================================

//------------------------------------------------------------------------
// test_case_directed_divu_1_basic
//------------------------------------------------------------------------

task test_case_directed_divu_1_basic();
  h.t.test_case_begin( "test_case_directed_divu_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 6"  );
  h.asm( 'h204, "addi x2, x0, 3"  );
  h.asm( 'h208, "divu x3, x1, x2" );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_0006, 1 ); // addi x1, x0, 2
  h.check_trace( 'h204, 2, 'h0000_0003, 1 ); // addi x2, x0, 3
  h.check_trace( 'h208, 3, 'h0000_0002, 1 ); // divu x3, x1, x2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_divu_2_x0
//------------------------------------------------------------------------

task test_case_directed_divu_2_x0();
  h.t.test_case_begin( "test_case_directed_divu_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1, x0, 1"  );
  h.asm( 'h204, "addi x2, x0, 2"  );
  h.asm( 'h208, "divu x0, x0, x1" );
  h.asm( 'h20c, "divu x3, x0, x2" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h01, 1 ); // addi x1, x0, 1
  h.check_trace( 'h204,  2, 'h02, 1 ); // addi x2, x0, 2
  h.check_trace( 'h208, 'x, 'x,   0 ); // divu x0, x0, x1
  h.check_trace( 'h20c,  3, 'h00, 1 ); // divu x3, x0, x2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_divu_3_pos
//------------------------------------------------------------------------

task test_case_directed_divu_3_pos();
  h.t.test_case_begin( "test_case_directed_divu_3_pos" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0,  24"   );
  h.asm( 'h204, "addi x2,  x0,  12"   );
  h.asm( 'h208, "addi x3,  x0,  3"    );
  h.asm( 'h20c, "addi x4,  x0,  2"    );

  h.asm( 'h210, "divu x5,  x1,  x2"   );
  h.asm( 'h214, "divu x6,  x2,  x3"   );
  h.asm( 'h218, "divu x7,  x3,  x4"   );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 24,        1 ); // addi x1,  x0,  24
  h.check_trace( 'h204, 2, 12,        1 ); // addi x2,  x0,  12
  h.check_trace( 'h208, 3, 3,         1 ); // addi x3,  x0,  3
  h.check_trace( 'h20c, 4, 2,         1 ); // addi x4,  x0,  2

  h.check_trace( 'h210, 5, 2,         1 ); // divu x5,  x1,  x2
  h.check_trace( 'h214, 6, 4,         1 ); // divu x6,  x2,  x3
  h.check_trace( 'h218, 7, 1,         1 ); // divu x7,  x3,  x4

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_divu_4_neg
//------------------------------------------------------------------------

task test_case_directed_divu_4_neg();
  h.t.test_case_begin( "test_case_directed_divu_4_neg" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0,  -48"   );
  h.asm( 'h204, "addi x2,  x0,   12"   );
  h.asm( 'h208, "addi x3,  x0,  -6"    );
  h.asm( 'h20c, "addi x4,  x0,  -4"    );

  h.asm( 'h210, "divu x5,  x1,  x2"    );
  h.asm( 'h214, "divu x6,  x2,  x3"    );
  h.asm( 'h218, "divu x7,  x3,  x4"    );

  // Check each executed instruction

  h.check_trace( 'h200, 1, -48,         1 ); // addi x1,  x0, -48
  h.check_trace( 'h204, 2,  12,         1 ); // addi x2,  x0,  12
  h.check_trace( 'h208, 3, -6,          1 ); // addi x3,  x0,  -6
  h.check_trace( 'h20c, 4, -4,          1 ); // addi x4,  x0,  -4

  h.check_trace( 'h210, 5, 'h1555_5551, 1 ); // divu x5,  x1,  x2
  h.check_trace( 'h214, 6, 0,           1 ); // divu x6,  x2,  x3
  h.check_trace( 'h218, 7, 0,           1 ); // divu x7,  x3,  x4

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_divu_5_zero
//------------------------------------------------------------------------

task test_case_directed_divu_5_zero();
  h.t.test_case_begin( "test_case_directed_divu_5_zero" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi x1,  x0,  1"  );
  h.asm( 'h204, "divu x2,  x1,  x0"  );
  h.asm( 'h208, "divu x3,  x0,  x0" );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_0001, 1 ); // addi x1,  x0,  1
  h.check_trace( 'h204, 2, 'hffff_ffff, 1 ); // divu x2,  x1,  x0
  h.check_trace( 'h208, 3, 'hffff_ffff, 1 ); // divu x3,  x0,  x0

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_divu_6_overflow
//------------------------------------------------------------------------

task test_case_directed_divu_6_overflow();
  h.t.test_case_begin( "test_case_directed_divu_6_overflow" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "lui  x1,  0x80000"  );
  h.asm( 'h204, "addi x2,  x0,  -1"  );
  h.asm( 'h208, "divu x3,  x1,  x2" );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h8000_0000, 1 ); // lui  x1,  0x80000
  h.check_trace( 'h204, 2, 'hffff_ffff, 1 ); // addi x2,  x0,  -1
  h.check_trace( 'h208, 3, 'h0000_0000, 1 ); // divu x3,  x1,  x2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_divu_tests
//------------------------------------------------------------------------

task run_directed_divu_tests();
  test_case_directed_divu_1_basic();
  test_case_directed_divu_2_x0();
  test_case_directed_divu_3_pos();
  test_case_directed_divu_4_neg();
  test_case_directed_divu_5_zero();
  test_case_directed_divu_6_overflow();
endtask
