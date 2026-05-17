//========================================================================
// auipc_test_cases
//========================================================================
// Adapted from Cornell's ECE 2300

//------------------------------------------------------------------------
// test_case_directed_auipc_1_basic
//------------------------------------------------------------------------

task test_case_directed_auipc_1_basic();
  h.t.test_case_begin( "test_case_directed_auipc_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "auipc x1, 0x001"  );

  // Check each executed instruction

  h.check_trace( 'h200, 1, 'h0000_1200, 1 ); // auipc  x1, 0x001

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// test_case_directed_auipc_extreme
//------------------------------------------------------------------------

task test_case_directed_auipc_2_extreme();
  h.t.test_case_begin( "test_case_directed_auipc_2_extreme" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "auipc  x0, 0x12345" );

  h.asm( 'h204, "auipc  x1, 0x00000" );
  h.asm( 'h208, "auipc  x2, 0xfffff" );
  h.asm( 'h20c, "auipc  x3, 0x7ffff" );
  h.asm( 'h210, "auipc  x4, 0x80000" );

  // Check each executed instruction

  h.check_trace( 'h200, 'x, 'x,   0 ); // auipc  x0, 0x12345
  
  h.check_trace( 'h204, 1, 'h0000_0204, 1 ); // auipc  x1, 0x00000
  h.check_trace( 'h208, 2, 'hffff_f208, 1 ); // auipc  x2, 0xfffff
  h.check_trace( 'h20c, 3, 'h7fff_f20c, 1 ); // auipc  x3, 0x7ffff
  h.check_trace( 'h210, 4, 'h8000_0210, 1 ); // auipc  x4, 0x80000

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_directed_auipc_tests
//------------------------------------------------------------------------

task run_directed_auipc_tests();
  test_case_directed_auipc_1_basic();
  test_case_directed_auipc_2_extreme();
endtask
