//========================================================================
// TestOstream.v
//========================================================================
// A FL output stream for receiving messages from DUTs

`ifndef TEST_FL_TESTOSTREAM_V
`define TEST_FL_TESTOSTREAM_V

`include "test/FLTestUtils.v"

module TestOstream #(
  parameter type t_msg        = logic[31:0],
  parameter p_recv_intv_delay = 0
)(
  input  logic clk,
  input  logic rst,
  
  input  t_msg msg,
  input  logic val,
  output logic rdy
);

  FLTestUtils t( .* );

  initial begin
    rdy = 1'b0;
  end

  //----------------------------------------------------------------------
  // recv
  //----------------------------------------------------------------------
  // A function to receive a message across a stream interface

  t_msg dut_msg, exp_msg;
  logic msg_recv;

  // verilator lint_off BLKSEQ
  
  task recv (
    input t_msg test_msg
  );

    rdy      = 1'b0;
    msg_recv = 1'b0;
    exp_msg  = test_msg;
    
    // Delay for the send interval
    for( int i = 0; i < p_recv_intv_delay; i = i + 1 ) begin
      @( posedge clk );
      #1;
    end

    rdy = 1'b1;

    do begin
      #2
      msg_recv = val;
      dut_msg  = msg;
      @( posedge clk );
      #1;
    end while( !msg_recv );

    `CHECK_EQ( dut_msg, exp_msg );

    rdy = 1'b0;

  endtask

  // verilator lint_on BLKSEQ

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
    if( val & rdy )
      trace = $sformatf("%x", msg);
    else if( rdy )
      trace = {(trace_len){" "}};
    else if( val )
      trace = {{(trace_len-1){" "}}, "#"};
    else
      trace = {{(trace_len-1){" "}}, "."};
  endfunction

endmodule

`endif // TEST_FL_TESTISTREAM_V
