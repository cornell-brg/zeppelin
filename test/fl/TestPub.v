//========================================================================
// TestPub.v
//========================================================================
// A FL publisher for sending notifications to DUTs

`ifndef TEST_FL_TESTPUB_V
`define TEST_FL_TESTPUB_V

module TestPub #(
  parameter type t_msg = logic[31:0]
)(
  input  logic clk,
  
  output t_msg msg,
  output logic val
);

  initial begin
    msg = 'x;
    val = 1'b0;
  end

  //----------------------------------------------------------------------
  // pub
  //----------------------------------------------------------------------
  // A function to send a notification

  task pub (
    input t_msg dut_msg
  );

    val = 1'b1;
    msg = dut_msg;

    @( posedge clk );
    #1;

    val = 1'b0;
    msg = 'x;

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
    if( val )
      trace = $sformatf("%x", msg);
    else
      trace = {(trace_len){" "}};
  endfunction

endmodule

`endif // TEST_FL_TESTPUB_V
