//========================================================================
// bne_test_cases.v
//========================================================================

//----------------------------------------------------------------------
// test_case_bne_taken
//----------------------------------------------------------------------

task test_case_bne_taken();
  t.test_case_begin( "test_case_bne_taken" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc           seq_num op1         op2         imm         waddr  uop
      send('h0000_0200, 0,      'h00000001, 'h00000002, 'h0000_0010, 5'h1, OP_BNE);
      send('h0000_0204, 1,      'h80808080, 'h08080808, 'hffff_fffc, 5'h3, OP_BNE);
      send('h0123_4560, 2,      'h00000000, 'hffffffff, 'h1000_0000, 5'h5, OP_BNE);
    end

    begin
      //   pc           seq_num waddr wdata wen
      recv('h0000_0200, 0,      0,    0,    0);
      recv('h0000_0204, 1,      0,    0,    0);
      recv('h0123_4560, 2,      0,    0,    0);
    end

    begin
      //     seq_num target
      ctrl_flow(0,      'h0000_0210);
      ctrl_flow(1,      'h0000_0200);
      ctrl_flow(2,      'h1123_4560);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_bne_not_taken
//----------------------------------------------------------------------

task test_case_bne_not_taken();
  t.test_case_begin( "test_case_bne_not_taken" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc           seq_num op1         op2         imm         waddr  uop
      send('h0000_0200, 0,      'h00000001, 'h00000001, 'h0000_0010, 5'h1, OP_BNE);
      send('h0000_0204, 1,      'h12345678, 'h12345678, 'hffff_fffc, 5'h3, OP_BNE);
      send('h0123_4560, 2,      'h00000000, 'h00000000, 'h1000_0000, 5'h5, OP_BNE);

      send('h0102_0304, 3,      'h00000000, 'h00000001, 'h0000_0000, 5'h7, OP_BNE);
    end

    begin
      //   pc           seq_num waddr wdata wen
      recv('h0000_0200, 0,      0,    0,    0);
      recv('h0000_0204, 1,      0,    0,    0);
      recv('h0123_4560, 2,      0,    0,    0);
      recv('h0102_0304, 3,      0,    0,    0);
    end

    begin
      // Only the last is received
      //     seq_num target
      ctrl_flow(3,      'h0102_0304);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_bne_test_cases
//----------------------------------------------------------------------

task run_bne_test_cases();
  test_case_bne_taken();
  test_case_bne_not_taken();
endtask
