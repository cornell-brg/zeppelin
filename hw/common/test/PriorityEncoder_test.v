//========================================================================
// PriorityEncoder_test.v
//========================================================================
// A testbench for our parametrized priority encoder

`include "test/TestUtils.v"
`include "hw/common/PriorityEncoder.v"

import TestEnv::*;

//========================================================================
// PriorityEncoderTestSuite
//========================================================================
// A test suite for a particular parametrization of the priority encoder

module PriorityEncoderTestSuite #(
  parameter p_suite_num = 0,
  parameter p_width = 4
);
  string suite_name = $sformatf("%0d: PriorityEncoderTestSuite_%0d", 
                                p_suite_num, p_width);

  //----------------------------------------------------------------------
  // Setup
  //----------------------------------------------------------------------

  // verilator lint_off UNUSED
  logic clk, rst;
  // verilator lint_on UNUSED

  TestUtils t( .* );

  //----------------------------------------------------------------------
  // Instantiate design under test
  //----------------------------------------------------------------------

  logic [p_width-1:0] dut_in;
  logic [p_width-1:0] dut_out;

  PriorityEncoder #(
    .p_width (p_width)
  ) DUT (
    .in  (dut_in),
    .out (dut_out)
  );

  //----------------------------------------------------------------------
  // check
  //----------------------------------------------------------------------
  // All tasks start at #1 after the rising edge of the clock. So we
  // write the inputs #1 after the rising edge, and check the outputs #1
  // before the next rising edge.

  task check (
    input logic [p_width-1:0] in,
    input logic [p_width-1:0] out
  );
    if ( !t.failed ) begin
      dut_in = in;

      #8;

      if ( t.verbose ) begin
        $display( "%3d: %b > %b", t.cycles,
                  dut_in, dut_out );
      end

      `CHECK_EQ( dut_out, out );

      #2;

    end
  endtask

  //----------------------------------------------------------------------
  // test_case_1_basic
  //----------------------------------------------------------------------

  task test_case_1_basic();
    t.test_case_begin( "test_case_1_basic" );
    if( !t.run_test ) return;

    //     in                    out
    check( p_width'('b0000), p_width'('b0000) );
    check( p_width'('b0001), p_width'('b0001) );
    check( p_width'('b0010), p_width'('b0010) );
    check( p_width'('b0011), p_width'('b0001) );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_2_one_hot
  //----------------------------------------------------------------------

  task test_case_2_one_hot();
    t.test_case_begin( "test_case_2_one_hot" );
    if( !t.run_test ) return;

    for( int i = 0; i < p_width; i = i + 1 )
      check( p_width'(1 << i), p_width'(1 << i) );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_3_multi_bit
  //----------------------------------------------------------------------

  task test_case_3_multi_bit();
    t.test_case_begin( "test_case_3_multi_bit" );
    if( !t.run_test ) return;

    check( p_width'('b0011), p_width'('b0001) );
    check( p_width'('b0111), p_width'('b0001) );
    check( p_width'('b1111), p_width'('b0001) );
    check( p_width'('b1110), p_width'('b0010) );
    check( p_width'('b1100), p_width'('b0100) );
    check( p_width'('b1000), p_width'('b1000) );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_4_random
  //----------------------------------------------------------------------

  logic [p_width-1:0] rand_in;
  logic [p_width-1:0] exp_out;

  task test_case_4_random();
    t.test_case_begin( "test_case_4_random" );
    if( !t.run_test ) return;

    for( int i = 0; i < 20; i = i + 1 ) begin
      rand_in = p_width'( $urandom() );

      // Get correct output
      if( rand_in == 0 )
        exp_out = 0;
      else begin
        exp_out = p_width'('b1);
        for( int j = 0; j < p_width; j = j + 1 ) begin
          if( rand_in[j] ) break;
          exp_out = exp_out << 1;
        end
      end

      check( rand_in, exp_out );

    end

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // run_test_suite
  //----------------------------------------------------------------------

  task run_test_suite();
    t.test_suite_begin( suite_name );

    test_case_1_basic();
    test_case_2_one_hot();
    test_case_3_multi_bit();
    test_case_4_random();

  endtask
endmodule

//========================================================================
// PriorityEncoder_test
//========================================================================

module PriorityEncoder_test;
  PriorityEncoderTestSuite #(1)     suite_1();
  PriorityEncoderTestSuite #(2,  8) suite_2();
  PriorityEncoderTestSuite #(3, 32) suite_3();
  PriorityEncoderTestSuite #(3,  1) suite_4();

  int s;

  initial begin
    test_bench_begin( `__FILE__ );
    s = get_test_suite();

    if ((s <= 0) || (s == 1)) suite_1.run_test_suite();
    if ((s <= 0) || (s == 2)) suite_2.run_test_suite();
    if ((s <= 0) || (s == 3)) suite_3.run_test_suite();
    if ((s <= 0) || (s == 4)) suite_4.run_test_suite();

    test_bench_end();
  end
endmodule
