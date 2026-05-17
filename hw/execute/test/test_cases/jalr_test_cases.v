//========================================================================
// jalr_test_cases.v
//========================================================================

//----------------------------------------------------------------------
// test_case_jalr_basic
//----------------------------------------------------------------------

task test_case_jalr_basic();
  t.test_case_begin( "test_case_jalr_basic" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc           seq_num op1 op2 imm waddr uop
      send('h0000_0200, 0,      'x, 'x, 'x, 5'h1, OP_JALR);
      send('h0000_0204, 1,      'x, 'x, 'x, 5'h1, OP_JALR);
      send('h0123_4560, 2,      'x, 'x, 'x, 5'h1, OP_JALR);
    end

    begin
      //   pc           seq_num waddr wdata           wen
      recv('h0000_0200, 0,      5'h1, 'h0000_0204,    1);
      recv('h0000_0204, 1,      5'h1, 'h0000_0208,    1);
      recv('h0123_4560, 2,      5'h1, 'h0123_4564,    1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_jalr_test_cases
//----------------------------------------------------------------------

task run_jalr_test_cases();
  test_case_jalr_basic();
endtask
