//========================================================================
// TestSub.v
//========================================================================
// A FL subscriber for receiving notifications from DUTs

`ifndef TEST_FL_TESTSUB_V
`define TEST_FL_TESTSUB_V

`include "test/FLTestUtils.v"

module TestSub #(
  parameter type t_msg = logic[31:0]
)(
  input logic clk,
  
  input t_msg msg,
  input logic val
);
  
  FLTestUtils t( .rst( 1'b0 ), .* );

  //----------------------------------------------------------------------
  // sub
  //----------------------------------------------------------------------
  // A function to receive a notification

  t_msg dut_msg;
  logic msg_recv;
  logic waiting;

  initial waiting = 1'b0;

  task sub (
    input t_msg exp_msg
  );

    waiting = 1'b1;

    do begin
      #2
      msg_recv = val;
      dut_msg  = msg;
      @( posedge clk );
      #1;
    end while( !msg_recv );
    
    `CHECK_EQ( dut_msg, exp_msg );

    waiting = 1'b0;

  endtask

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

  string test_trace;
  int trace_len;
  initial begin
    test_trace = $sformatf("%x", msg);
    trace_len = test_trace.len();
  end

  function string trace(
    // verilator lint_off UNUSEDSIGNAL
    int trace_level
    // verilator lint_on UNUSEDSIGNAL
  );
    if( val & waiting )
      trace = $sformatf("%x", msg);
    else if( val )
      trace = {{(trace_len-1){" "}}, "X"};
    else if( waiting )
      trace = {(trace_len){" "}};
    else
      trace = {{(trace_len-1){" "}}, "."};
  endfunction

endmodule

`endif // TEST_FL_TESTSUB_V
