//========================================================================
// FetchUnit_test.v
//========================================================================
// A testbench for the superscalar fetch unit

`include "hw/fetch/FetchUnit.v"
`include "intf/F__DIntf.v"
`include "intf/MemIntf.v"
`include "intf/ControlFlowNotif.v"
`include "test/fl/MemIntfTestServer.v"
`include "test/fl/TestOstream.v"
`include "test/fl/TestPub.v"
`include "test/fl/TestMPub.v"

import TestEnv::*;

//========================================================================
// FetchUnitTestSuite
//========================================================================
// A test suite for a particular parametrization of the Fetch unit

module FetchUnitTestSuite #(
  parameter p_suite_num            = 0,
  parameter p_opaq_bits            = 8,
  parameter p_seq_num_bits         = 5,
  parameter p_reclaim_width        = 2,
  parameter p_max_in_flight        = 16,
  parameter p_mem_send_intv_delay  = 0,
  parameter p_mem_recv_intv_delay  = 0,
  parameter p_D_recv_intv_delay    = 0,
  parameter p_num_fe_lanes         = 2,
  parameter p_num_be_lanes         = 2
);

  string suite_name = $sformatf("%0d: FetchUnitTestSuite_%0d_%0d_%0d_%0d_%0d_%0d_%0d_%0dfe_%0dbe",
                                p_suite_num, p_opaq_bits, p_seq_num_bits,
                                p_reclaim_width, p_max_in_flight,
                                p_mem_send_intv_delay, p_mem_recv_intv_delay,
                                p_D_recv_intv_delay,
                                p_num_fe_lanes, p_num_be_lanes);

  localparam p_num_seq_nums = 2 ** p_seq_num_bits;

  //----------------------------------------------------------------------
  // Setup
  //----------------------------------------------------------------------

  logic clk, rst;
  TestUtils t( .* );

  `MEM_REQ_DEFINE_SS ( p_opaq_bits, p_num_fe_lanes );
  `MEM_RESP_DEFINE_SS( p_opaq_bits, p_num_fe_lanes );

  //----------------------------------------------------------------------
  // Instantiate design under test
  //----------------------------------------------------------------------

  localparam [1:0] INST_STATUS_INVALID = 2'b00,
                   INST_STATUS_READY   = 2'b01;

  MemIntf #(
    .p_opaq_bits (p_opaq_bits),
    .p_num_words (p_num_fe_lanes)
  ) mem_intf ();

  F__DIntf #(
    .p_seq_num_bits (p_seq_num_bits)
  ) F__D_intf [p_num_fe_lanes] ();

  CommitNotif #(
    .p_seq_num_bits (p_seq_num_bits)
  ) commit_notif [p_num_be_lanes] ();

  ControlFlowNotif #(
    .p_seq_num_bits (p_seq_num_bits)
  ) ctrl_flow_notif();

  FetchUnit #(
    .p_reclaim_width (p_reclaim_width),
    .p_max_in_flight (p_max_in_flight),
    .p_num_fe_lanes  (p_num_fe_lanes),
    .p_num_be_lanes  (p_num_be_lanes)
  ) dut (
    .mem    (mem_intf),
    .D      (F__D_intf),
    .commit (commit_notif),
    .ctrl_flow (ctrl_flow_notif),
    .*
  );

  //----------------------------------------------------------------------
  // FL Memory
  //----------------------------------------------------------------------

  MemIntfTestServer #(
    .t_req_msg         (`MEM_REQ_SS ( p_opaq_bits, p_num_fe_lanes )),
    .t_resp_msg        (`MEM_RESP_SS( p_opaq_bits, p_num_fe_lanes )),
    .p_send_intv_delay (p_mem_send_intv_delay),
    .p_recv_intv_delay (p_mem_recv_intv_delay),
    .p_opaq_bits       (p_opaq_bits),
    .p_num_words       (p_num_fe_lanes)
  ) fl_mem (
    .dut (mem_intf),
    .*
  );

  //----------------------------------------------------------------------
  // FL D Ostreams
  //----------------------------------------------------------------------

  typedef struct packed {
    logic               [31:0] inst;
    logic               [31:0] pc;
    logic [p_seq_num_bits-1:0] seq_num;
    logic                [1:0] inst_status;
  } t_f__d_msg;

  t_f__d_msg f__d_msg [p_num_fe_lanes];

  genvar i;
  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin : F__D_OSTREAMS
      assign f__d_msg[i].inst        = F__D_intf[i].inst;
      assign f__d_msg[i].pc          = F__D_intf[i].pc;
      assign f__d_msg[i].seq_num     = F__D_intf[i].seq_num;
      assign f__d_msg[i].inst_status = F__D_intf[i].inst_status;
    end
  endgenerate

  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin : F__D_OSTREAM_GEN
      TestOstream #( t_f__d_msg, p_D_recv_intv_delay ) D_Ostream (
        .msg (f__d_msg[i]),
        .val (F__D_intf[i].val),
        .rdy (F__D_intf[i].rdy),
        .*
      );
    end
  endgenerate

  t_f__d_msg msgs_to_recv     [p_num_fe_lanes];
  logic      msgs_to_recv_val [p_num_fe_lanes];

  generate
    for( i = 0; i < p_num_fe_lanes; i++ ) begin
      always @( posedge clk ) begin
        #1;
        if( msgs_to_recv_val[i] ) begin
          F__D_OSTREAM_GEN[i].D_Ostream.recv(
            msgs_to_recv[i]
          );
        end

        // verilator lint_off BLKSEQ
        msgs_to_recv_val[i] = 1'b0;
        // verilator lint_on BLKSEQ
      end

      initial begin
        msgs_to_recv_val[i] = 1'b0;
      end
    end
  endgenerate

  t_f__d_msg pipe_msg [p_num_fe_lanes];

  task recv_f__d_xfer(
    input logic               [31:0] inst       [p_num_fe_lanes],
    input logic               [31:0] pc         [p_num_fe_lanes],
    input logic [p_seq_num_bits-1:0] seq_num    [p_num_fe_lanes],
    input logic                [1:0] inst_status [p_num_fe_lanes],
    input logic                      valid       [p_num_fe_lanes]
  );
    for( int j = 0; j < p_num_fe_lanes; j++ ) begin
      automatic int jj = j;
      fork
        begin
          pipe_msg[jj].inst        = inst[jj];
          pipe_msg[jj].pc          = pc[jj];
          pipe_msg[jj].seq_num     = seq_num[jj];
          pipe_msg[jj].inst_status = inst_status[jj];
          msgs_to_recv[jj]        = pipe_msg[jj];
          msgs_to_recv_val[jj]    = valid[jj];
          while(msgs_to_recv_val[jj])
            #1;
        end
      join_none
    end
    wait fork;
  endtask

  //----------------------------------------------------------------------
  // Commit Notification
  //----------------------------------------------------------------------

  typedef struct packed {
    logic                 [31:0] pc;
    logic   [p_seq_num_bits-1:0] seq_num;
    logic                  [4:0] waddr;
    logic                 [31:0] wdata;
    logic                        wen;
  } t_commit_msg;

  t_commit_msg commit_msg     [p_num_be_lanes];
  logic        commit_msg_val [p_num_be_lanes];

  generate
    for( i = 0; i < p_num_be_lanes; i++ ) begin
      assign commit_notif[i].pc      = commit_msg[i].pc;
      assign commit_notif[i].seq_num = commit_msg[i].seq_num;
      assign commit_notif[i].waddr   = commit_msg[i].waddr;
      assign commit_notif[i].wdata   = commit_msg[i].wdata;
      assign commit_notif[i].wen     = commit_msg[i].wen;
      assign commit_notif[i].val     = commit_msg_val[i];
    end
  endgenerate

  logic                 [31:0] unused_commit_pc    [p_num_be_lanes];
  logic                  [4:0] unused_commit_waddr [p_num_be_lanes];
  logic                 [31:0] unused_commit_wdata [p_num_be_lanes];
  logic                        unused_commit_wen   [p_num_be_lanes];

  generate
    for( i = 0; i < p_num_be_lanes; i++ ) begin
      assign unused_commit_pc[i]    = commit_notif[i].pc;
      assign unused_commit_waddr[i] = commit_notif[i].waddr;
      assign unused_commit_wdata[i] = commit_notif[i].wdata;
      assign unused_commit_wen[i]   = commit_notif[i].wen;
    end
  endgenerate

  TestMPub #(
    .t_msg      (t_commit_msg),
    .p_num_msgs (p_num_be_lanes)
  ) free_pub (
    .msg (commit_msg),
    .val (commit_msg_val),
    .*
  );

  t_commit_msg msg_to_commit     [p_num_be_lanes];
  logic        msg_to_commit_val [p_num_be_lanes];

  task seq_free(
    input logic [p_seq_num_bits-1:0] seq_num       [p_num_be_lanes],
    input logic                      seq_num_valid [p_num_be_lanes]
  );
    for( int j = 0; j < p_num_be_lanes; j++ ) begin
      msg_to_commit[j].seq_num = seq_num[j];
      msg_to_commit[j].pc      = '0;
      msg_to_commit[j].waddr   = '0;
      msg_to_commit[j].wdata   = '0;
      msg_to_commit[j].wen     = '0;
      msg_to_commit_val[j]     = seq_num_valid[j];
    end

    free_pub.pub( msg_to_commit, msg_to_commit_val );
  endtask

  //----------------------------------------------------------------------
  // CtrlFlow Notification
  //----------------------------------------------------------------------

  typedef struct packed {
    logic [p_seq_num_bits-1:0] seq_num;
    logic               [31:0] target;
  } t_ctrl_flow_msg;

  t_ctrl_flow_msg ctrl_flow_msg;

  assign ctrl_flow_notif.seq_num = ctrl_flow_msg.seq_num;
  assign ctrl_flow_notif.target  = ctrl_flow_msg.target;

  TestPub #( t_ctrl_flow_msg ) ctrl_flow_pub (
    .msg (ctrl_flow_msg),
    .val (ctrl_flow_notif.redirect_val),
    .*
  );

  task ctrl_flow(
    input logic [p_seq_num_bits-1:0] seq_num,
    input logic               [31:0] target
  );
    t_ctrl_flow_msg m;
    m.seq_num = seq_num;
    m.target  = target;

    ctrl_flow_pub.pub( m );
  endtask

  //----------------------------------------------------------------------
  // Linetracing
  //----------------------------------------------------------------------

  string trace;

  // verilator lint_off BLKSEQ
  always @( posedge clk ) begin
    #2;
    trace = "";

    // trace = {trace, fl_mem.trace( t.trace_level )};
    // trace = {trace, " | "};
    // trace = {trace, D_Ostream_0.trace( t.trace_level )};
    // trace = {trace, " "};
    // trace = {trace, D_Ostream_1.trace( t.trace_level )};
    // trace = {trace, " - "};
    // trace = {trace, commit_pub_0.trace( t.trace_level )};
    // trace = {trace, " "};
    // trace = {trace, commit_pub_1.trace( t.trace_level )};
    // trace = {trace, " - "};
    // trace = {trace, ctrl_flow_pub.trace( t.trace_level )};

    t.trace( trace );
  end
  // verilator lint_on BLKSEQ

  //----------------------------------------------------------------------
  // Include test cases
  //----------------------------------------------------------------------

  `include "hw/fetch/test/test_cases/l5_basic_test_cases.v"
  `include "hw/fetch/test/test_cases/l5_ctrl_flow_test_cases.v"

  //----------------------------------------------------------------------
  // run_test_suite
  //----------------------------------------------------------------------

  task run_test_suite();
    t.test_suite_begin( suite_name );

    run_l5_basic_test_cases();
    run_l5_ctrl_flow_test_cases();
  endtask
endmodule

//========================================================================
// FetchUnit_test
//========================================================================

module FetchUnit_test;

  // Defaults (2 fe lanes, 2 be lanes)
  FetchUnitTestSuite #(
    .p_suite_num           (1)
  ) suite_1();

  // 1 fe lane, 1 be lane, few seq nums, few in flight
  FetchUnitTestSuite #(
    .p_suite_num           (2),
    .p_seq_num_bits        (2),
    .p_max_in_flight       (4),
    .p_num_fe_lanes        (1),
    .p_num_be_lanes        (1)
  ) suite_2();

  // 2 fe lane, 2 be lane, few seq nums, few in flight
  FetchUnitTestSuite #(
    .p_suite_num           (3),
    .p_seq_num_bits        (2),
    .p_max_in_flight       (4)
  ) suite_3();

  // 2 fe lane, 2 be lane, few seq nums
  FetchUnitTestSuite #(
    .p_suite_num           (4),
    .p_seq_num_bits        (2)
  ) suite_4();

  // 2 fe lane, 2 be lane, reclaim single seq num per cycle
  FetchUnitTestSuite #(
    .p_suite_num           (5),
    .p_reclaim_width       (1)
  ) suite_5();

  // 4 fe lanes, 4 be lanes
  FetchUnitTestSuite #(
    .p_suite_num           (6),
    .p_num_fe_lanes        (4),
    .p_num_be_lanes        (4)
  ) suite_6();

  // 1 fe lane, 4 be lanes
  FetchUnitTestSuite #(
    .p_suite_num           (7),
    .p_num_fe_lanes        (1),
    .p_num_be_lanes        (4)
  ) suite_7();

  // 4 fe lanes, 1 be lane
  FetchUnitTestSuite #(
    .p_suite_num           (8),
    .p_num_fe_lanes        (4),
    .p_num_be_lanes        (1)
  ) suite_8();

  // 8 fe lanes, 8 be lanes
  FetchUnitTestSuite #(
    .p_suite_num           (9),
    .p_num_fe_lanes        (8),
    .p_num_be_lanes        (8)
  ) suite_9();

  // 4 fe lanes, 2 be lanes, mem and D_intf delays
  FetchUnitTestSuite #(
    .p_suite_num           (10),
    .p_num_fe_lanes        (4),
    .p_num_be_lanes        (4),
    .p_mem_send_intv_delay (10),
    .p_mem_recv_intv_delay (10),
    .p_D_recv_intv_delay   (10)
  ) suite_10();

  // 4 fe lanes, 2 be lanes, mem delays
  FetchUnitTestSuite #(
    .p_suite_num           (11),
    .p_num_fe_lanes        (4),
    .p_num_be_lanes        (4),
    .p_mem_send_intv_delay (10),
    .p_mem_recv_intv_delay (10)
  ) suite_11();

  // 4 fe lanes, 2 be lanes, D_intf delays
  FetchUnitTestSuite #(
    .p_suite_num           (12),
    .p_num_fe_lanes        (4),
    .p_num_be_lanes        (4),
    .p_D_recv_intv_delay   (10)
  ) suite_12();

  int s;

  initial begin
    test_bench_begin( `__FILE__ );
    s = get_test_suite();

    if ((s <= 0) || (s ==  1)) suite_1.run_test_suite();
    if ((s <= 0) || (s ==  2)) suite_2.run_test_suite();
    if ((s <= 0) || (s ==  3)) suite_3.run_test_suite();
    if ((s <= 0) || (s ==  4)) suite_4.run_test_suite();
    if ((s <= 0) || (s ==  5)) suite_5.run_test_suite();
    if ((s <= 0) || (s ==  6)) suite_6.run_test_suite();
    if ((s <= 0) || (s ==  7)) suite_7.run_test_suite();
    if ((s <= 0) || (s ==  8)) suite_8.run_test_suite();
    if ((s <= 0) || (s ==  9)) suite_9.run_test_suite();
    if ((s <= 0) || (s == 10)) suite_10.run_test_suite();
    if ((s <= 0) || (s == 11)) suite_11.run_test_suite();
    if ((s <= 0) || (s == 12)) suite_12.run_test_suite();

    test_bench_end();
  end
endmodule
