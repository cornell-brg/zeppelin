//========================================================================
// basic_test_cases.v
//========================================================================
// Basic tests for a sequence number generator

//----------------------------------------------------------------------
// test_case_1_basic
//----------------------------------------------------------------------

task test_case_1_basic();
  t.test_case_begin( "test_case_1_basic" );
  if( !t.run_test ) return;

  seq_alloc( 0 );
  seq_alloc( 1 );

  check_allocated( 2 );

  seq_free( 0 );
  seq_free( 1 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_2_reclaim
//----------------------------------------------------------------------

task test_case_2_reclaim();
  t.test_case_begin( "test_case_2_reclaim" );
  if( !t.run_test ) return;

  seq_alloc( 0 );
  seq_alloc( 1 );

  check_allocated( 2 );

  seq_free( 0 );
  seq_free( 1 );

  // Need one more cycle to reclaim
  @( posedge clk );
  #1;

  check_allocated( 0 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_3_ooo_free
//----------------------------------------------------------------------

task test_case_3_ooo_free();
  t.test_case_begin( "test_case_3_ooo_free" );
  if( !t.run_test ) return;

  seq_alloc( 0 );
  seq_alloc( 1 );

  check_allocated( 2 );

  seq_free( 1 );
  seq_free( 0 );

  // Need at max two more cycles to reclaim
  @( posedge clk );
  @( posedge clk );
  #1;

  check_allocated( 0 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_4_reclaim_speed
//----------------------------------------------------------------------
// Test how fast entries are reclaimed

task test_case_4_reclaim_speed();
  t.test_case_begin( "test_case_4_reclaim_speed" );
  if( !t.run_test ) return;

  for( int i = 0; i < 16; i = i + 1 )
    seq_alloc( p_seq_num_bits'(i) );

  for( int i = 1; i < 16; i = i + 1 )
    seq_free( p_seq_num_bits'(i) );

  // Check we still have 16 outstanding entries to reclaim
  check_allocated( 16 );

  // Free the last
  seq_free( 0 );

  // Only wait the needed time
  for( int i = 0; i < 16 / p_reclaim_width; i = i + 1 )
    @( posedge clk );
  #1;

  check_allocated( 0 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_5_capacity
//----------------------------------------------------------------------

task test_case_5_capacity();
  t.test_case_begin( "test_case_5_capacity" );
  if( !t.run_test ) return;

  // Fill up to maximum entries
  for( int i = 0; i < p_num_seq_nums - 1; i = i + 1 ) begin
    seq_alloc(
      p_seq_num_bits'(i)
    );
  end

  check_allocated( p_num_seq_nums - 1 );

  // Free an entry, then allocate one after
  for( int i = 0; i < 10; i = i + 1 ) begin
    seq_free(
      p_seq_num_bits'(i)
    );
    seq_alloc(
      p_seq_num_bits'(i - 1)
    );
  end

  check_allocated( p_num_seq_nums - 1 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_basic_test_cases
//----------------------------------------------------------------------

task run_basic_test_cases();
  test_case_1_basic();
  test_case_2_reclaim();
  test_case_3_ooo_free();
  test_case_4_reclaim_speed();
  test_case_5_capacity();
endtask

