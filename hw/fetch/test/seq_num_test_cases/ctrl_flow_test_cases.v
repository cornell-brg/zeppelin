//========================================================================
// ctrl_flow_test_cases.v
//========================================================================
// Tests that a sequence number generator can handle ctrl_flowing

//----------------------------------------------------------------------
// test_case_ctrl_flow_basic
//----------------------------------------------------------------------

task test_case_ctrl_flow_basic();
  t.test_case_begin( "test_case_ctrl_flow_basic" );
  if( !t.run_test ) return;

  seq_alloc( 0 );
  seq_alloc( 1 );

  check_allocated( 2 );

  ctrl_flow( 0 ); // 1 is ctrl_flowed
  seq_free( 0 );

  // Need at most two more cycles to reclaim
  @( posedge clk );
  @( posedge clk );
  #1;

  check_allocated( 0 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_ctrl_flow_capacity
//----------------------------------------------------------------------

task test_case_ctrl_flow_capacity();
  t.test_case_begin( "test_case_ctrl_flow_capacity" );
  if( !t.run_test ) return;

  for( int i = 0; i < p_num_seq_nums - 1; i = i + 1 ) begin
    seq_alloc(
      p_seq_num_bits'(i)
    );
  end

  check_allocated( p_num_seq_nums - 1 );

  ctrl_flow( 0 ); // All but 0 are ctrl_flowed
  seq_free( 0 );

  // Check that we can continue allocating
  for( int i = 1; i < p_num_seq_nums; i = i + 1 ) begin
    seq_alloc(
      p_seq_num_bits'(i)
    );
  end

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_ctrl_flow_test_cases
//----------------------------------------------------------------------

task run_ctrl_flow_test_cases();
  test_case_ctrl_flow_basic();
  test_case_ctrl_flow_capacity();
endtask

