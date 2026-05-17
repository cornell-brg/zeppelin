//========================================================================
// ooo_test_cases.v
//========================================================================
// Check that our WCU can reorder instructions

//----------------------------------------------------------------------
// test_case_ooo_basic
//----------------------------------------------------------------------

task test_case_ooo_basic();
  t.test_case_begin( "test_case_ooo_basic" );
  if( !t.run_test ) return;

  fork
    begin
      //   pipe pc  seq_num addr  data          wen preg ppreg
      send(0,   '0, 1,      5'h1, 32'hdeadbeef, 1,  32,  1 );
      send(0,   '1, 0,      5'h2, 32'hcafecafe, 1,  33,  2 );
    end

    begin
      //           seq_num addr  data          wen preg
      complete_sub(1,      5'h1, 32'hdeadbeef, 1,  32 );
      complete_sub(0,      5'h2, 32'hcafecafe, 1,  33 );
    end

    begin
      //         pc  seq_num addr  data          wen ppreg
      commit_sub('1, 0,      5'h2, 32'hcafecafe, 1,  2 );
      commit_sub('0, 1,      5'h1, 32'hdeadbeef, 1,  1 );
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_basic_test_cases
//----------------------------------------------------------------------

task run_ooo_test_cases();
  test_case_ooo_basic();
endtask
