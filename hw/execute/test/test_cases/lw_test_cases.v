//========================================================================
// lw_test_cases.v
//========================================================================

//----------------------------------------------------------------------
// test_case_lw_basic
//----------------------------------------------------------------------

task test_case_lw_basic();
  t.test_case_begin( "test_case_lw_basic" );
  if( !t.run_test ) return;

  //               addr   data
  fl_mem.init_mem( 'h100, 'hdeadbeef );
  fl_mem.init_mem( 'h104, 'hcafecafe );

  fork
    begin
      //        pc     seq_num op1 op2     waddr uop    mem_data
      send_mem( 'h200, 0,      0,  'h100,  5'h1, OP_LW, 'x );
      send_mem( 'h204, 1,      0,  'h104,  5'h2, OP_LW, 'x );
    end

    begin
      //    pc     seq_num waddr wdata       wen
      recv( 'h200, 0,      5'h1, 'hdeadbeef, 1);
      recv( 'h204, 1,      5'h2, 'hcafecafe, 1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_lw_repeat
//----------------------------------------------------------------------

task test_case_lw_repeat();
  t.test_case_begin( "test_case_lw_repeat" );
  if( !t.run_test ) return;

  //               addr   data
  fl_mem.init_mem( 'h100, 'hba5eba11 );

  fork
    begin
      //        pc     seq_num op1 op2     waddr uop    mem_data
      send_mem( 'h200, 0,      0,  'h100,  5'h1, OP_LW, 'h10101010 );
      send_mem( 'h204, 1,      0,  'h100,  5'h2, OP_LW, 'h20202020 );
      send_mem( 'h208, 2,      0,  'h100,  5'h3, OP_LW, 'h30303030 );
      send_mem( 'h20c, 3,      0,  'h100,  5'h4, OP_LW, 'h40404040 );
    end

    begin
      //    pc     seq_num waddr wdata       wen
      recv( 'h200, 0,      5'h1, 'hba5eba11, 1);
      recv( 'h204, 1,      5'h2, 'hba5eba11, 1);
      recv( 'h208, 2,      5'h3, 'hba5eba11, 1);
      recv( 'h20c, 3,      5'h4, 'hba5eba11, 1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_lw_offset
//----------------------------------------------------------------------

task test_case_lw_offset();
  t.test_case_begin( "test_case_lw_offset" );
  if( !t.run_test ) return;

  //               addr   data
  fl_mem.init_mem( 'h100, 'hf0f0f0f0 );
  fl_mem.init_mem( 'h104, 'he0e0e0e0 );
  fl_mem.init_mem( 'h108, 'hd0d0d0d0 );
  fl_mem.init_mem( 'h10c, 'hc0c0c0c0 );

  fork
    begin
      //        pc     seq_num op1 op2     waddr  uop    mem_data
      send_mem( 'h200, 0,      0,  'h100,  5'h1f, OP_LW, 'h10101010 );
      send_mem( 'h204, 1,      4,  'h100,  5'h1e, OP_LW, 'h20202020 );
      send_mem( 'h208, 2,      8,  'h100,  5'h1d, OP_LW, 'h30303030 );
      send_mem( 'h20c, 3,     12,  'h100,  5'h1c, OP_LW, 'h40404040 );
    end

    begin
      //    pc     seq_num waddr  wdata       wen
      recv( 'h200, 0,      5'h1f, 'hf0f0f0f0, 1);
      recv( 'h204, 1,      5'h1e, 'he0e0e0e0, 1);
      recv( 'h208, 2,      5'h1d, 'hd0d0d0d0, 1);
      recv( 'h20c, 3,      5'h1c, 'hc0c0c0c0, 1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_lw_test_cases
//----------------------------------------------------------------------

task run_lw_test_cases();
  test_case_lw_basic();
  test_case_lw_repeat();
  test_case_lw_offset();
endtask
