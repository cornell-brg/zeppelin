//========================================================================
// FLProcTestHarness.v
//========================================================================
// A testing harness to run directed tests on the functional-level
// processor

`ifndef HW_TOP_TEST_FLPROCTESTHARNESS_V
`define HW_TOP_TEST_FLPROCTESTHARNESS_V

`include "asm/assemble.v"
`include "fl/fl_vtrace.v"
`include "test/TestUtils.v"

import TestEnv::*;

module FLProcTestHarness();

  //----------------------------------------------------------------------
  // Setup
  //----------------------------------------------------------------------

  // verilator lint_off UNUSEDSIGNAL
  logic clk, rst;
  // verilator lint_on UNUSEDSIGNAL
  TestUtils t( .* );

  //----------------------------------------------------------------------
  // Testing tasks
  //----------------------------------------------------------------------

  task asm(
    input logic [31:0] addr,
    input string       inst
  );
    fl_init( addr, assemble( inst, addr ) );
  endtask

  task data(
    input logic [31:0] addr,
    input logic [31:0] data
  );
    fl_init( addr, data );
  endtask

  logic      dut_success;
  fl_trace_t dut_trace;
  string     trace;

  task check_trace(
    input logic [31:0] pc,
    input logic  [4:0] waddr,
    input logic [31:0] wdata,
    input logic        wen
  );
    dut_success = fl_trace( dut_trace );

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Linetracing
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Add a check for verbosity; test utilities will only display if
    // verbose, but we want to avoid string processing if possible for
    // speed

    if( t.verbose ) begin
      trace = $sformatf("(%b) ", dut_success);
      trace = {trace, fl_trace_str( dut_trace )};
      t.trace( trace );
    end

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // Check trace
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    if( !dut_success ) begin
      // Invalid trace - force a failure
      `CHECK_EQ( 1'b1, 1'b0 );
    end

    `CHECK_EQ( dut_trace.pc,  pc  );
    `CHECK_EQ( dut_trace.wen, wen );

    if( wen ) begin
      `CHECK_EQ( dut_trace.waddr, waddr );
      `CHECK_EQ( dut_trace.wdata, wdata );
    end
  endtask
endmodule

`endif // HW_TOP_TEST_FLPROCTESTHARNESS_V
