//========================================================================
// sw_test_cases.v
//========================================================================

//----------------------------------------------------------------------
// test_case_sw_basic
//----------------------------------------------------------------------

task test_case_sw_basic();
  t.test_case_begin( "test_case_sw_basic" );
  if( !t.run_test ) return;

  fork
    begin
      //        pc     seq_num op1 op2     waddr uop    mem_data
      send_mem( 'h200, 0,      0,  'h100,  'x,   OP_SW, 'hcafef00d );
      send_mem( 'h204, 1,      0,  'h100,  5'h1, OP_LW, 'x );
    end

    begin
      //    pc     seq_num waddr wdata       wen
      recv( 'h200, 0,      '0,   '0,         0);
      recv( 'h204, 1,      5'h1, 'hcafef00d, 1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_sw_repeat
//----------------------------------------------------------------------

task test_case_sw_repeat();
  t.test_case_begin( "test_case_sw_repeat" );
  if( !t.run_test ) return;

  fork
    begin
      //        pc     seq_num op1 op2     waddr uop    mem_data
      send_mem( 'h200, 0,      0,  'h100,  'x,   OP_SW, 'h10101010 );
      send_mem( 'h204, 1,      0,  'h100,  'h1f, OP_LW, 'x         );
      send_mem( 'h208, 2,      0,  'h100,  'x,   OP_SW, 'h20202020 );
      send_mem( 'h20c, 3,      0,  'h100,  'h1e, OP_LW, 'x         );
      send_mem( 'h210, 4,      0,  'h100,  'x,   OP_SW, 'h30303030 );
      send_mem( 'h214, 5,      0,  'h100,  'h1d, OP_LW, 'x         );
      send_mem( 'h218, 6,      0,  'h100,  'x,   OP_SW, 'h40404040 );
      send_mem( 'h21c, 7,      0,  'h100,  'h1c, OP_LW, 'x         );
    end

    begin
      //    pc     seq_num waddr wdata       wen
      recv( 'h200, 0,      '0,   '0,         0);
      recv( 'h204, 1,      'h1f, 'h10101010, 1);
      recv( 'h208, 2,      '0,   '0,         0);
      recv( 'h20c, 3,      'h1e, 'h20202020, 1);
      recv( 'h210, 4,      '0,   '0,         0);
      recv( 'h214, 5,      'h1d, 'h30303030, 1);
      recv( 'h218, 6,      '0,   '0,         0);
      recv( 'h21c, 7,      'h1c, 'h40404040, 1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_sw_offset
//----------------------------------------------------------------------

task test_case_sw_offset();
  t.test_case_begin( "test_case_sw_offset" );
  if( !t.run_test ) return;

  fork
    begin
      //        pc     seq_num op1 op2     waddr  uop    mem_data
      send_mem( 'h200, 0,      0,  'h100,  'x,    OP_SW, 'h01234567 );
      send_mem( 'h204, 1,      4,  'h100,  'x,    OP_SW, 'h89abcdef );
      send_mem( 'h208, 2,      8,  'h100,  'x,    OP_SW, 'h76543210 );
      send_mem( 'h20c, 3,     12,  'h100,  'x,    OP_SW, 'hfedcba98 );
      send_mem( 'h210, 4,      0,  'h100,  5'h0f, OP_LW, 'x         );
      send_mem( 'h214, 5,      4,  'h100,  5'h0e, OP_LW, 'x         );
      send_mem( 'h218, 6,      8,  'h100,  5'h0d, OP_LW, 'x         );
      send_mem( 'h21c, 7,     12,  'h100,  5'h0c, OP_LW, 'x         );
    end

    begin
      //    pc     seq_num waddr  wdata       wen
      recv( 'h200, 0,      '0,   '0,          0);
      recv( 'h204, 1,      '0,   '0,          0);
      recv( 'h208, 2,      '0,   '0,          0);
      recv( 'h20c, 3,      '0,   '0,          0);
      recv( 'h210, 4,      5'h0f, 'h01234567, 1);
      recv( 'h214, 5,      5'h0e, 'h89abcdef, 1);
      recv( 'h218, 6,      5'h0d, 'h76543210, 1);
      recv( 'h21c, 7,      5'h0c, 'hfedcba98, 1);
    end
  join
endtask

//----------------------------------------------------------------------
// run_sw_test_cases
//----------------------------------------------------------------------

task run_sw_test_cases();
  test_case_sw_basic();
  test_case_sw_repeat();
  test_case_sw_offset();
endtask
