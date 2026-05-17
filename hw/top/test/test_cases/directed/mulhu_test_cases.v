//========================================================================
// mulhu_test_cases.v
//========================================================================

//------------------------------------------------------------------------
// test_case_directed_mulhu_1_basic
//------------------------------------------------------------------------

task test_case_directed_mulhu_1_basic();
  h.t.test_case_begin( "test_case_directed_mulhu_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "lui   x1, 0x00020"  );
  h.asm( 'h204, "lui   x2, 0x00030"  );
  h.asm( 'h208, "mulhu x3, x1, x2"   );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0002_0000, 1 ); // lui   x1, 0x00020
  h.check_trace( 'h204, 2, 'h0003_0000, 1 ); // lui   x2, 0x00030
  h.check_trace( 'h208, 3, 'h0000_0006, 1 ); // mulhu x3, x1, x2

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_mulhu_2_x0
//------------------------------------------------------------------------

task test_case_directed_mulhu_2_x0();
  h.t.test_case_begin( "test_case_directed_mulhu_2_x0" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi  x1, x0, 1"  );
  h.asm( 'h204, "addi  x2, x0, 2"  );
  h.asm( 'h208, "mulhu x0, x0, x0" );
  h.asm( 'h20c, "mulhu x0, x0, x1" );
  h.asm( 'h210, "mulhu x0, x2, x0" );
  h.asm( 'h214, "mulhu x3, x0, x1" );
  h.asm( 'h218, "mulhu x4, x2, x0" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h01, 1 ); // addi  x1, x0, 1
  h.check_trace( 'h204,  2, 'h02, 1 ); // addi  x2, x0, 2
  h.check_trace( 'h208, 'x, 'x,   0 ); // mulhu x0, x0, x0
  h.check_trace( 'h20c, 'x, 'x,   0 ); // mulhu x0, x0, x1
  h.check_trace( 'h210, 'x, 'x,   0 ); // mulhu x0, x2, x0
  h.check_trace( 'h214,  3, 'h00, 1 ); // mulhu x3, x0, x1
  h.check_trace( 'h218,  4, 'h00, 1 ); // mulhu x4, x2, x0

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_mulhu_3_upper_bit
//------------------------------------------------------------------------

task test_case_directed_mulhu_3_upper_bit();
  h.t.test_case_begin( "test_case_directed_mulhu_3_upper_bit" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "lui   x1, 0x80000" );
  h.asm( 'h204, "lui   x2, 0x7ffff" );
  h.asm( 'h208, "lui   x3, 0xfffff" );

  h.asm( 'h20c, "mulhu x4,  x1,  x2"   );
  h.asm( 'h210, "mulhu x5,  x2,  x3"   );
  h.asm( 'h214, "mulhu x6,  x1,  x3"   );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h8000_0000, 1 ); // lui   x1, 0x80000
  h.check_trace( 'h204, 2, 'h7fff_f000, 1 ); // lui   x2, 0x7ffff
  h.check_trace( 'h208, 3, 'hffff_f000, 1 ); // lui   x3, 0xfffff

  h.check_trace( 'h20c, 4, 'h3fff_f800, 1 ); // mulhu x4,  x1,  x2
  h.check_trace( 'h210, 5, 'h7fff_e800, 1 ); // mulhu x5,  x2,  x3
  h.check_trace( 'h214, 6, 'h7fff_f800, 1 ); // mulhu x6,  x1,  x3

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_mulhu_tests
//------------------------------------------------------------------------

task run_directed_mulhu_tests();
  test_case_directed_mulhu_1_basic();
  test_case_directed_mulhu_2_x0();
  test_case_directed_mulhu_3_upper_bit();
endtask
