//========================================================================
// ImmGen_test.v
//========================================================================
// A testbench for our immediate generator

`include "hw/decode_issue/ImmGen.v"
`include "test/TestUtils.v"

import TestEnv::*;

//========================================================================
// RegfileTestSuite
//========================================================================
// A test suite for the immediate generator

module ImmGenTestSuite #(
  parameter p_suite_num  = 0
);
  string suite_name = $sformatf("%0d: ImmGenTestSuite", p_suite_num);

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

  logic [31:0] dut_inst;
  rv_imm_type  dut_imm_sel;
  logic [31:0] dut_imm;

  ImmGen DUT (
    .inst    (dut_inst),
    .imm_sel (dut_imm_sel),
    .imm     (dut_imm)
  );

  //----------------------------------------------------------------------
  // check
  //----------------------------------------------------------------------
  // All tasks start at #1 after the rising edge of the clock. So we
  // write the inputs #1 after the rising edge, and check the outputs #1
  // before the next rising edge.

  task check (
    input logic [31:0] inst,
    input rv_imm_type  imm_sel,
    input logic [31:0] imm
  );
    if ( !t.failed ) begin
      dut_imm_sel = imm_sel;
      dut_inst    = inst;

      #8;

      if ( t.verbose ) begin
        $display( "%3d: %s %h > %h", t.cycles,
                  dut_imm_sel.name(), dut_inst, dut_imm );
      end

      `CHECK_EQ( dut_imm, imm );

      #2;

    end
  endtask

  //----------------------------------------------------------------------
  // test_case_1_imm_i
  //----------------------------------------------------------------------

  task test_case_1_imm_i();
    t.test_case_begin( "test_case_1_imm_i" );
    if( !t.run_test ) return;

    //     inst                                        imm_sel imm
    check( 32'b0_010101_0101_0_01010101_0101_0_1010101, IMM_I, 32'b000000000000000000000_010101_0101_0 );
    check( 32'b1_000000_1111_0_01010101_0101_0_1010101, IMM_I, 32'b111111111111111111111_000000_1111_0 );
    check( 32'b0_111111_0000_1_01010101_0101_0_1010101, IMM_I, 32'b000000000000000000000_111111_0000_1 );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_2_imm_s
  //----------------------------------------------------------------------

  task test_case_2_imm_s();
    t.test_case_begin( "test_case_2_imm_s" );
    if( !t.run_test ) return;

    //     inst                                        imm_sel imm
    check( 32'b0_010101_0101_0_01010101_0101_0_1010101, IMM_S, 32'b000000000000000000000_010101_0101_0 );
    check( 32'b1_000000_0101_0_01010101_1111_0_1010101, IMM_S, 32'b111111111111111111111_000000_1111_0 );
    check( 32'b0_111111_0101_0_01010101_0000_1_1010101, IMM_S, 32'b000000000000000000000_111111_0000_1 );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_3_imm_b
  //----------------------------------------------------------------------

  task test_case_3_imm_b();
    t.test_case_begin( "test_case_3_imm_b" );
    if( !t.run_test ) return;

    //     inst                                        imm_sel imm
    check( 32'b0_010101_0101_0_01010101_0101_0_1010101, IMM_B, 32'b00000000000000000000_0_010101_0101_0 );
    check( 32'b1_000000_0101_0_01010101_1111_0_1010101, IMM_B, 32'b11111111111111111111_0_000000_1111_0 );
    check( 32'b0_111111_0101_0_01010101_0000_1_1010101, IMM_B, 32'b00000000000000000000_1_111111_0000_0 );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_4_imm_u
  //----------------------------------------------------------------------

  task test_case_4_imm_u();
    t.test_case_begin( "test_case_4_imm_u" );
    if( !t.run_test ) return;

    //     inst                                        imm_sel imm
    check( 32'b0_010101_0101_0_01010101_0101_0_1010101, IMM_U, 32'b0_010101_0101_0_01010101_000000000000 );
    check( 32'b1_000000_1111_0_11111111_0101_0_1010101, IMM_U, 32'b1_000000_1111_0_11111111_000000000000 );
    check( 32'b0_111111_0000_1_00000000_0101_0_1010101, IMM_U, 32'b0_111111_0000_1_00000000_000000000000 );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // test_case_5_imm_j
  //----------------------------------------------------------------------

  task test_case_5_imm_j();
    t.test_case_begin( "test_case_5_imm_j" );
    if( !t.run_test ) return;

    //     inst                                        imm_sel imm
    check( 32'b0_010101_0101_0_01010101_0101_0_1010101, IMM_J, 32'b000000000000_01010101_0_010101_0101_0 );
    check( 32'b1_000000_1111_0_11111111_0101_0_1010101, IMM_J, 32'b111111111111_11111111_0_000000_1111_0 );
    check( 32'b0_111111_0000_1_00000000_0101_0_1010101, IMM_J, 32'b000000000000_00000000_1_111111_0000_0 );

    t.test_case_end();
  endtask

  //----------------------------------------------------------------------
  // run_test_suite
  //----------------------------------------------------------------------

  task run_test_suite();
    t.test_suite_begin( suite_name );

    test_case_1_imm_i();
    test_case_2_imm_s();
    test_case_3_imm_b();
    test_case_4_imm_u();
    test_case_5_imm_j();

  endtask
endmodule

//========================================================================
// Regfile_test
//========================================================================

module ImmGen_test;
  ImmGenTestSuite #(1) suite_1();

  int s;

  initial begin
    test_bench_begin( `__FILE__ );
    s = get_test_suite();

    if ((s <= 0) || (s == 1)) suite_1.run_test_suite();

    test_bench_end();
  end
endmodule
