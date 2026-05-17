//========================================================================
// add_test_cases.v
//========================================================================

//----------------------------------------------------------------------
// test_case_add_basic
//----------------------------------------------------------------------

task test_case_add_basic();
  t.test_case_begin( "test_case_add_basic" );
  if( !t.run_test ) return;

  fork
    //   pc  seq_num op1 op2 waddr uop
    send('0, 0,      1,  2,  5'h1, OP_ADD);

    //   pc  seq_num waddr wdata wen
    recv('0, 0,      5'h1, 3,    1);
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_add_signed
//----------------------------------------------------------------------

task test_case_add_signed();
  t.test_case_begin( "test_case_add_signed" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc  seq_num op1 op2 waddr uop
      send('0, 1,      4,  3,  5'h1, OP_ADD);
      send('1, 2,     -1,  1,  5'h4, OP_ADD);
      send('0, 3,      4, -6,  5'h2, OP_ADD);
      send('1, 4,      2,  0,  5'h5, OP_ADD);
      send('0, 5,      0, -7,  5'h3, OP_ADD);
    end

    begin
      //   pc  seq_num waddr wdata wen
      recv('0, 1,      5'h1,  7,   1);
      recv('1, 2,      5'h4,  0,   1);
      recv('0, 3,      5'h2, -2,   1);
      recv('1, 4,      5'h5,  2,   1);
      recv('0, 5,      5'h3, -7,   1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_add_test_cases
//----------------------------------------------------------------------

task run_add_test_cases();
  test_case_add_basic();
  test_case_add_signed();
endtask
