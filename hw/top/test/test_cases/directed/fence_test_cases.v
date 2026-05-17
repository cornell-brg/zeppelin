//========================================================================
// fence_test_cases
//========================================================================

//------------------------------------------------------------------------
// test_case_directed_fence_1_basic
//------------------------------------------------------------------------
// Quick check that a fence doesn't modify registers

task test_case_directed_fence_1_basic();
  h.t.test_case_begin( "test_case_directed_fence_1_basic" );
  if( !h.t.run_test ) return;
  fl_reset();

  // Write assembly program into memory

  h.asm( 'h200, "addi  x1, x0, 1" );
  h.asm( 'h204, "addi  x2, x0, 2" );
  h.asm( 'h208, "addi  x3, x0, 3" );
  h.asm( 'h20c, "addi  x4, x0, 4" );

  h.asm( 'h210, "fence rw, rw"  );

  h.asm( 'h214, "addi  x1, x1, 1" );
  h.asm( 'h218, "addi  x2, x2, 2" );
  h.asm( 'h21c, "addi  x3, x3, 3" );
  h.asm( 'h220, "addi  x4, x4, 4" );

  // Check each executed instruction

  h.check_trace( 'h200,  1, 'h0000_0001, 1 ); // addi  x1, x0, 1
  h.check_trace( 'h204,  2, 'h0000_0002, 1 ); // addi  x2, x0, 2
  h.check_trace( 'h208,  3, 'h0000_0003, 1 ); // addi  x3, x0, 3
  h.check_trace( 'h20c,  4, 'h0000_0004, 1 ); // addi  x4, x0, 4
  h.check_trace( 'h210, 'x, 'x,          0 ); // fence rw, rw
  h.check_trace( 'h214,  1, 'h0000_0002, 1 ); // addi  x1, x1, 1
  h.check_trace( 'h218,  2, 'h0000_0004, 1 ); // addi  x2, x2, 2
  h.check_trace( 'h21c,  3, 'h0000_0006, 1 ); // addi  x3, x3, 3
  h.check_trace( 'h220,  4, 'h0000_0008, 1 ); // addi  x4, x4, 4

  h.t.test_case_end();
endtask

//------------------------------------------------------------------------
// run_instruction_tests
//------------------------------------------------------------------------

task run_directed_fence_tests();
  test_case_directed_fence_1_basic();
endtask
