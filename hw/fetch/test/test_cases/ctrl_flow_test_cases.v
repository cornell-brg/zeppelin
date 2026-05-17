//========================================================================
// ctrl_flow_test_cases.v
//========================================================================
// Test cases to check handling of a ctrl_flow

//----------------------------------------------------------------------
// test_case_ctrl_flow_basic
//----------------------------------------------------------------------

task test_case_ctrl_flow_basic();
  t.test_case_begin( "test_case_ctrl_flow_basic" );
  if( !t.run_test ) return;

  //               addr  data
  fl_mem.init_mem( 'h200, 32'hdeadbeef );
  fl_mem.init_mem( 'h204, 32'hcafef00d );
  fl_mem.init_mem( 'h208, 32'hbaadb0ba );

  //    inst          pc     seq_num
  recv( 32'hdeadbeef, 'h200, 0 );

  //      seq_num target
  ctrl_flow( 0,      'h208 );

  recv( 32'hbaadb0ba, 'h208, 1 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_ctrl_flow_forward
//----------------------------------------------------------------------

task test_case_ctrl_flow_forward();
  t.test_case_begin( "test_case_ctrl_flow_forward" );
  if( !t.run_test ) return;

  //               addr  data
  fl_mem.init_mem( 'h200, 32'h10101010 );
  fl_mem.init_mem( 'h204, 32'h20202020 );
  fl_mem.init_mem( 'h208, 32'h30303030 );
  fl_mem.init_mem( 'h20c, 32'h40404040 );
  fl_mem.init_mem( 'h210, 32'h50505050 );

  //    inst          pc     seq_num
  recv( 32'h10101010, 'h200, 0 );
  recv( 32'h20202020, 'h204, 1 );

  //      seq_num target
  ctrl_flow( 0,      'h20c );

  recv( 32'h40404040, 'h20c, 1 );
  recv( 32'h50505050, 'h210, 2 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_ctrl_flow_backward
//----------------------------------------------------------------------

task test_case_ctrl_flow_backward();
  t.test_case_begin( "test_case_ctrl_flow_backward" );
  if( !t.run_test ) return;

  //               addr  data
  fl_mem.init_mem( 'h200, 32'hf0f0f0f0 );
  fl_mem.init_mem( 'h204, 32'he0e0e0e0 );
  fl_mem.init_mem( 'h208, 32'hd0d0d0d0 );
  fl_mem.init_mem( 'h20c, 32'hc0c0c0c0 );

  //    inst          pc     seq_num
  recv( 32'hf0f0f0f0, 'h200, 0 );
  recv( 32'he0e0e0e0, 'h204, 1 );
  recv( 32'hd0d0d0d0, 'h208, 2 );

  //      seq_num target
  ctrl_flow( 1,      'h200 );

  recv( 32'hf0f0f0f0, 'h200, 2 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_ctrl_flow_many
//----------------------------------------------------------------------

task test_case_ctrl_flow_many();
  t.test_case_begin( "test_case_ctrl_flow_many" );
  if( !t.run_test ) return;

  //               addr  data
  fl_mem.init_mem( 'h200, 32'hf0f0f0f0 );
  fl_mem.init_mem( 'h204, 32'he0e0e0e0 );
  fl_mem.init_mem( 'h208, 32'hd0d0d0d0 );
  fl_mem.init_mem( 'h20c, 32'hc0c0c0c0 );

  //    inst          pc     seq_num
  recv( 32'hf0f0f0f0, 'h200, 0 );

  // Delay to build up in-flight requests
  for( int i = 0; i < 5; i = i + 1 ) begin
    @( posedge clk );
    #1;
  end

  //      seq_num target
  ctrl_flow( 0,      'h200 );

  recv( 32'hf0f0f0f0, 'h200, 1 );

  for( int i = 0; i < 5; i = i + 1 ) begin
    @( posedge clk );
    #1;
  end

  //      seq_num target
  ctrl_flow( 1,      'h200 );

  recv( 32'hf0f0f0f0, 'h200, 2 );

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_ctrl_flow_multi
//----------------------------------------------------------------------

task test_case_ctrl_flow_multi();
  t.test_case_begin( "test_case_ctrl_flow_multi" );
  if( !t.run_test ) return;

  //               addr  data
  fl_mem.init_mem( 'h200, 32'hf0f0f0f0 );
  fl_mem.init_mem( 'h204, 32'he0e0e0e0 );
  fl_mem.init_mem( 'h208, 32'hd0d0d0d0 );
  fl_mem.init_mem( 'h20c, 32'hc0c0c0c0 );

  //    inst          pc     seq_num
  recv( 32'hf0f0f0f0, 'h200, 0 );

  for( int j = 1; j < 4; j = j + 1 ) begin
    // Delay to build up in-flight requests
    for( int i = 0; i < 10; i = i + 1 ) begin
      @( posedge clk );
      #1;
    end

    //      seq_num                 target
    ctrl_flow( p_seq_num_bits'(j - 1), 'h200 );

    recv( 32'hf0f0f0f0, 'h200, p_seq_num_bits'(j) );
  end

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_ctrl_flow_max_in_flight
//----------------------------------------------------------------------

task test_case_ctrl_flow_max_in_flight();
  t.test_case_begin( "test_case_ctrl_flow_max_in_flight" );
  if( !t.run_test ) return;

  for( int i = 0; i < 3 * p_max_in_flight + 4; i = i + 1 ) begin
    //               addr                data
    fl_mem.init_mem( 'h200 + 32'(4 * i), 32'(i) );
  end

  // Wait a while, then ctrl_flow multiple times
  for( int i = 0; i < 3; i = i + 1 ) begin
    for( int j = 0; j < p_max_in_flight; j = j + 1 ) begin
      @( posedge clk ); // Request is sent out
      #1;
    end
    ctrl_flow( 0, 'h200 );
  end

  // Check that we still receive the correct messages
  for( int i = 0; i < 2 * p_max_in_flight; i = i + 1 ) begin
    //    inst    pc              seq_num
    recv( 32'(i), 'h200 + 32'(4 * i), p_seq_num_bits'(i + 1) );
    commit( p_seq_num_bits'(i + 1) );
  end

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_ctrl_flow_test_cases
//----------------------------------------------------------------------

task run_ctrl_flow_test_cases();
  test_case_ctrl_flow_basic();
  test_case_ctrl_flow_forward();
  test_case_ctrl_flow_backward();
  test_case_ctrl_flow_many();
  test_case_ctrl_flow_multi();
  test_case_ctrl_flow_max_in_flight();
endtask
