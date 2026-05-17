//========================================================================
// add_test_cases.v
//========================================================================

//----------------------------------------------------------------------
// test_case_mul_pos_pos
//----------------------------------------------------------------------

task test_case_mul_pos_pos();
  t.test_case_begin( "test_case_mul_pos_pos" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc  seq_num op1           op2  waddr uop
      send('0, 1,                 4,  3,  5'h1, OP_MUL);
      send('1, 2,                12, 12,  5'h4, OP_MUL);
      send('0, 3,      32'h80000000,  2,  5'h2, OP_MUL);
    end

    begin
      //   pc  seq_num waddr wdata wen
      recv('0, 1,      5'h1,  12,  1);
      recv('1, 2,      5'h4, 144,  1);
      recv('0, 3,      5'h2,   0,  1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_mul_pos_neg
//----------------------------------------------------------------------

task test_case_mul_pos_neg();
  t.test_case_begin( "test_case_mul_pos_neg" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc  seq_num op1           op2  waddr uop   
      send('0, 1,                 4,  -3, 5'h1, OP_MUL);
      send('1, 0,                12, -12, 5'h4, OP_MUL);
      send('0, 1,      32'h80000000,  -2, 5'h2, OP_MUL);
    end

    begin
      //   pc  seq_num waddr wdata wen
      recv('0, 1,      5'h1,  -12, 1);
      recv('1, 0,      5'h4, -144, 1);
      recv('0, 1,      5'h2,    0, 1);
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_mul_neg_pos
//----------------------------------------------------------------------

task test_case_mul_neg_pos();
  t.test_case_begin( "test_case_mul_neg_pos" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc  seq_num op1  op2 waddr uop   
      send('0, 2,       -4,  3, 5'h1, OP_MUL);
      send('1, 2,      -12, 12, 5'h4, OP_MUL);
    end

    begin
      //   pc  seq_num waddr wdata wen
      recv('0, 2,      5'h1,  -12, 1 );
      recv('1, 2,      5'h4, -144, 1 );
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_mul_neg_neg
//----------------------------------------------------------------------

task test_case_mul_neg_neg();
  t.test_case_begin( "test_case_mul_neg_neg" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc  seq_num op1  op2  waddr uop    
      send('1, 0,      -4,  -3, 5'h1, OP_MUL);
      send('0, 0,     -12, -12, 5'h4, OP_MUL);
    end

    begin
      //   pc  seq_num waddr wdata wen
      recv('1, 0,      5'h1,  12,  1 );
      recv('0, 0,      5'h4, 144,  1 );
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_mul_zero
//----------------------------------------------------------------------

task test_case_mul_zero();
  t.test_case_begin( "test_case_mul_zero" );
  if( !t.run_test ) return;

  fork
    begin
      //   pc  seq_num op1 op2 waddr uop
      send('1, 3,      4,   0, 5'h1, OP_MUL);
      send('0, 2,      0,  12, 5'h4, OP_MUL);
      send('1, 1,      0,   0, 5'h2, OP_MUL);
    end

    begin
      //   pc  seq_num waddr wdata wen
      recv('1, 3,      5'h1, 0,    1 );
      recv('0, 2,      5'h4, 0,    1 );
      recv('1, 1,      5'h2, 0,    1 );
    end
  join

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// test_case_mul_random
//----------------------------------------------------------------------

logic               [31:0] rand_pc;
logic [p_seq_num_bits-1:0] rand_seq_num;
logic               [31:0] rand_op1, rand_op2, exp_out;
logic                [4:0] rand_waddr;

task test_case_mul_random();
  t.test_case_begin( "test_case_mul_random" );
  if( !t.run_test ) return;

  for( int i = 0; i < 20; i = i + 1 ) begin
    rand_pc      = 32'($urandom());
    rand_seq_num = p_seq_num_bits'($urandom());
    rand_op1     = 32'($urandom());
    rand_op2     = 32'($urandom());
    rand_waddr   = 5'($urandom());
    exp_out      = rand_op1 * rand_op2;

    fork
      send(rand_pc, rand_seq_num, rand_op1, rand_op2, rand_waddr, OP_MUL);
      recv(rand_pc, rand_seq_num, rand_waddr, exp_out, 1);
    join
  end

  t.test_case_end();
endtask

//----------------------------------------------------------------------
// run_mul_test_cases
//----------------------------------------------------------------------

task run_mul_test_cases();
  test_case_mul_pos_pos();
  test_case_mul_pos_neg();
  test_case_mul_neg_pos();
  test_case_mul_neg_neg();
  test_case_mul_zero();
  test_case_mul_random();
endtask
