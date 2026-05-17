//========================================================================
// Zeppelin_test_suites.vh
//========================================================================
// Shared macros and test suite instantiation template for Zeppelin tests.
//
// Usage (with golden tests):
//
//   `include "hw/top/test/ZeppelinTestHarness.v"
//   `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
//
//   module ZeppelinTestSuite_add #( `ZEPPELIN_SUITE_PARAMS );
//     `ZEPPELIN_SUITE_HARNESS
//     `include "hw/top/test/test_cases/directed/add_test_cases.v"
//     `include "hw/top/test/test_cases/golden/add_test_cases.v"
//     `ZEPPELIN_SUITE_RUN(add, run_golden_add_tests();)
//   endmodule
//
//   module Zeppelin_add_test;
//     `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_add
//     `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
//   endmodule
//
// Usage (directed tests only):
//
//   module ZeppelinTestSuite_fence #( `ZEPPELIN_SUITE_PARAMS );
//     `ZEPPELIN_SUITE_HARNESS
//     `include "hw/top/test/test_cases/directed/fence_test_cases.v"
//     `ZEPPELIN_SUITE_RUN(fence)
//   endmodule

`ifndef _ZEPPELIN_TEST_SUITES_VH
`define _ZEPPELIN_TEST_SUITES_VH

//----------------------------------------------------------------------
// Suite Module Parameters
//----------------------------------------------------------------------

// verilator lint_off DECLFILENAME

`define ZEPPELIN_SUITE_PARAMS \
  parameter p_suite_num               = 0,  \
  parameter p_opaq_bits               = 8,  \
  parameter p_seq_num_bits            = 5,  \
  parameter p_num_phys_regs           = 36, \
  parameter p_num_fe_lanes            = 2,  \
  parameter p_num_be_lanes            = 2,  \
  parameter p_iq_depth                = 4,  \
  parameter p_reclaim_width           = 4,  \
  parameter p_max_in_flight           = 4,  \
  parameter p_f_intf_fifo_depth       = 1,  \
  parameter p_x_intf_fifo_depth       = 1,  \
  parameter p_alu_d_intf_fifo_depth   = 1,  \
  parameter p_mul_d_intf_fifo_depth   = 1,  \
  parameter p_mem_d_intf_fifo_depth   = 1,  \
  parameter p_ctrl_d_intf_fifo_depth  = 1,  \
  parameter p_num_alus                = 1,  \
  parameter p_num_muls                = 1,  \
  parameter p_all_iq_in_order         = 0,  \
  parameter p_pipe_bypass             = 0,  \
  parameter p_muldivrem_sel           = 0,  \
  parameter p_enable_branch_pred      = 0,  \
  parameter p_btb_entries             = 64, \
  parameter p_btb_ways               = p_btb_entries, \
  parameter p_num_pipes               = p_num_alus + p_num_muls + 2, \
  parameter p_mem_send_intv_delay     = 1,  \
  parameter p_mem_recv_intv_delay     = 1,  \
  parameter [p_num_fe_lanes*8-1:0] p_sim_f2d_bp = '0, \
  parameter [p_num_pipes*8-1:0]    p_sim_d2x_bp = '0, \
  parameter [p_num_pipes*8-1:0]    p_sim_x2w_bp = '0

//----------------------------------------------------------------------
// Suite Harness Instantiation
//----------------------------------------------------------------------

`define ZEPPELIN_SUITE_HARNESS \
  string suite_name = $sformatf("%0d: ZeppelinTestSuite_%0d_%0d_%0d_%0d_%0d_%0d_%0d_%0d", \
                                p_suite_num, \
                                p_opaq_bits, p_seq_num_bits, p_num_phys_regs, p_num_be_lanes, p_iq_depth, \
                                p_mem_send_intv_delay, p_mem_recv_intv_delay, \
                                p_num_fe_lanes); \
  ZeppelinTestHarness #( \
    .p_opaq_bits              (p_opaq_bits), \
    .p_seq_num_bits           (p_seq_num_bits), \
    .p_num_phys_regs          (p_num_phys_regs), \
    .p_num_be_lanes           (p_num_be_lanes), \
    .p_iq_depth               (p_iq_depth), \
    .p_reclaim_width          (p_reclaim_width), \
    .p_max_in_flight          (p_max_in_flight), \
    .p_num_fe_lanes           (p_num_fe_lanes), \
    .p_f_intf_fifo_depth      (p_f_intf_fifo_depth), \
    .p_x_intf_fifo_depth      (p_x_intf_fifo_depth), \
    .p_alu_d_intf_fifo_depth  (p_alu_d_intf_fifo_depth), \
    .p_mul_d_intf_fifo_depth  (p_mul_d_intf_fifo_depth), \
    .p_mem_d_intf_fifo_depth  (p_mem_d_intf_fifo_depth), \
    .p_num_alus               (p_num_alus), \
    .p_num_muls               (p_num_muls), \
    .p_all_iq_in_order        (p_all_iq_in_order), \
    .p_pipe_bypass            (p_pipe_bypass), \
    .p_muldivrem_sel          (p_muldivrem_sel), \
    .p_enable_branch_pred     (p_enable_branch_pred), \
    .p_btb_entries            (p_btb_entries), \
    .p_btb_ways               (p_btb_ways), \
    .p_num_pipes              (p_num_pipes), \
    .p_mem_send_intv_delay    (p_mem_send_intv_delay), \
    .p_mem_recv_intv_delay    (p_mem_recv_intv_delay), \
    .p_sim_f2d_bp             (p_sim_f2d_bp), \
    .p_sim_d2x_bp             (p_sim_d2x_bp), \
    .p_sim_x2w_bp             (p_sim_x2w_bp) \
  ) h();

//----------------------------------------------------------------------
// Suite Run Task
//----------------------------------------------------------------------
// SUFFIX:      instruction name (e.g. add, bne, fence)
// GOLDEN_CALL: optional golden test call (e.g. run_golden_add_tests();)
//              omit for tests without golden test cases.

`define ZEPPELIN_SUITE_RUN(SUFFIX, GOLDEN_CALL=) \
  task run_test_suite(); \
    h.t.test_suite_begin( suite_name ); \
    run_directed_``SUFFIX``_tests(); \
    GOLDEN_CALL \
  endtask

`endif /* _ZEPPELIN_TEST_SUITES_VH */

//======================================================================
// Suite Instantiation Template
//======================================================================
// Included when ZEPPELIN_SUITE_MODULE is defined. Instantiates all
// standard test suites and the run block.

`ifdef ZEPPELIN_SUITE_MODULE

  //======================================================================
  // Category A: Baseline & Lane Configurations (Suites 1-8)
  //======================================================================

  // Suite 1: Default baseline (2 FE / 2 BE, 1 ALU / 1 MUL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num (1)
  ) suite_1();

  // Suite 2: Minimal single-lane (1 FE / 1 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (2),
    .p_num_fe_lanes (1),
    .p_num_be_lanes (1)
  ) suite_2();

  // Suite 3: Wide symmetric (4 FE / 4 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (3),
    .p_num_fe_lanes (4),
    .p_num_be_lanes (4)
  ) suite_3();

  // Suite 4: Non-power-of-2 symmetric (3 FE / 3 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (4),
    .p_num_fe_lanes (3),
    .p_num_be_lanes (3)
  ) suite_4();

  // Suite 5: Narrow fetch, wider commit (1 FE / 2 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (5),
    .p_num_fe_lanes (1),
    .p_num_be_lanes (2)
  ) suite_5();

  // Suite 6: Wide fetch, narrow commit (4 FE / 2 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (6),
    .p_num_fe_lanes (4),
    .p_num_be_lanes (2)
  ) suite_6();

  // Suite 7: Asymmetric non-pow2 + small seq (3 FE / 1 BE, ROB=4)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (7),
    .p_num_fe_lanes  (3),
    .p_num_be_lanes  (1),
    .p_seq_num_bits  (2),
    .p_num_phys_regs (34)
  ) suite_7();

  // Suite 8: Wide + cross-cut sizing (4 FE / 4 BE, ROB=16, 50 regs)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (8),
    .p_num_fe_lanes  (4),
    .p_num_be_lanes  (4),
    .p_seq_num_bits  (4),
    .p_num_phys_regs (50)
  ) suite_8();

  //======================================================================
  // Category B: Execution Unit Scaling (Suites 9-14)
  //======================================================================

  // Suite 9: Dual ALU (5 pipes: ALU0, ALU1, MUL0, MEM, CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num (9),
    .p_num_alus  (2)
  ) suite_9();

  // Suite 10: Quad ALU (7 pipes: ALU0-3, MUL0, MEM, CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num (10),
    .p_num_alus  (4)
  ) suite_10();

  // Suite 11: Dual MUL (5 pipes: ALU0, MUL0, MUL1, MEM, CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num (11),
    .p_num_muls  (2)
  ) suite_11();

  // Suite 12: Dual ALU + Dual MUL, wide
  //           (6 pipes: ALU0, ALU1, MUL0, MUL1, MEM, CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (12),
    .p_num_alus     (2),
    .p_num_muls     (2),
    .p_num_fe_lanes (4),
    .p_num_be_lanes (4)
  ) suite_12();

  // Suite 13: Quad ALU + Dual MUL, wide
  //           (8 pipes: ALU0-3, MUL0-1, MEM, CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (13),
    .p_num_alus     (4),
    .p_num_muls     (2),
    .p_num_fe_lanes (4),
    .p_num_be_lanes (4)
  ) suite_13();

  // Suite 14: Dual ALU + iterative mul, wide
  //           (5 pipes: ALU0, ALU1, MUL0, MEM, CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (14),
    .p_num_alus      (2),
    .p_muldivrem_sel (0),
    .p_num_fe_lanes  (4),
    .p_num_be_lanes  (4)
  ) suite_14();

  //======================================================================
  // Category C: MulDivRem Variants (Suites 15-23)
  //======================================================================
  // p_muldivrem_sel: 0 = fully iterative
  //                  1 = single-cycle mul + iterative div/rem
  //                  2 = fully single-cycle

  // Suite 15: Fully iterative baseline (default 4-pipe config)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (15),
    .p_muldivrem_sel (0)
  ) suite_15();

  // Suite 16: Fully iterative + deep IQ + deep FIFOs
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (16),
    .p_muldivrem_sel         (0),
    .p_iq_depth              (8),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4)
  ) suite_16();

  // Suite 17: Fully iterative + in-order IQ + bypass all pipes
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num       (17),
    .p_muldivrem_sel   (0),
    .p_all_iq_in_order (1),
    .p_pipe_bypass     (1)
  ) suite_17();

  // Suite 18: Single-cycle mul + iterative div/rem baseline
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (18),
    .p_muldivrem_sel (1)
  ) suite_18();

  // Suite 19: Single-cycle mul + iterative div/rem + deep IQ + deep FIFOs
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (19),
    .p_muldivrem_sel         (1),
    .p_iq_depth              (8),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4)
  ) suite_19();

  // Suite 20: Single-cycle mul + iterative div/rem + in-order IQ + bypass all pipes
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num       (20),
    .p_muldivrem_sel   (1),
    .p_all_iq_in_order (1),
    .p_pipe_bypass     (1)
  ) suite_20();

  // Suite 21: Fully single-cycle baseline
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (21),
    .p_muldivrem_sel (2)
  ) suite_21();

  // Suite 22: Fully single-cycle + deep IQ + deep FIFOs
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (22),
    .p_muldivrem_sel         (2),
    .p_iq_depth              (8),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4)
  ) suite_22();

  // Suite 23: Fully single-cycle + in-order IQ + bypass all pipes
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num       (23),
    .p_muldivrem_sel   (2),
    .p_all_iq_in_order (1),
    .p_pipe_bypass     (1)
  ) suite_23();

  //======================================================================
  // Category D: In-Order IQ & Pipe Bypass (Suites 24-25)
  //======================================================================
  // Note: never put backpressure on CTRL pipe — causes livelock.

  // Suite 24: All in-order IQ
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num       (24),
    .p_all_iq_in_order (1)
  ) suite_24();

  // Suite 25: In-order IQ + 4x4 lanes + F2D backpressure
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num       (25),
    .p_all_iq_in_order (1),
    .p_num_fe_lanes    (4),
    .p_num_be_lanes    (4),
    .p_sim_f2d_bp      ({8'd5, 8'd3, 8'd7, 8'd4})
  ) suite_25();

  //======================================================================
  // Category E: IQ Depth (Suites 26-28)
  //======================================================================

  // Suite 26: Shallow IQ (depth=2)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num (26),
    .p_iq_depth  (2)
  ) suite_26();

  // Suite 27: Deep IQ (depth=8)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num (27),
    .p_iq_depth  (8)
  ) suite_27();

  // Suite 28: Shallow IQ + bypass all pipes + small phys regs
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (28),
    .p_iq_depth      (2),
    .p_pipe_bypass   (1),
    .p_num_phys_regs (34)
  ) suite_28();

  //======================================================================
  // Category F: FIFO Depths (Suites 29-33)
  //======================================================================

  // Suite 29: All FIFOs deep (depth=4)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (29),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4)
  ) suite_29();

  // Suite 30: Deep FIFOs + 4x4 lanes + F2D and D2X backpressure
  //           D2X layout (4 pipes): {CTRL=0, MEM=5, MUL=3, ALU=4}
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (30),
    .p_num_fe_lanes          (4),
    .p_num_be_lanes          (4),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4),
    .p_sim_f2d_bp            ({8'd4, 8'd3, 8'd5, 8'd4}),
    .p_sim_d2x_bp            ({8'd0, 8'd5, 8'd3, 8'd4})
  ) suite_30();

  // Suite 31: All FIFOs medium (depth=2)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (31),
    .p_f_intf_fifo_depth     (2),
    .p_x_intf_fifo_depth     (2),
    .p_alu_d_intf_fifo_depth (2),
    .p_mul_d_intf_fifo_depth (2),
    .p_mem_d_intf_fifo_depth (2)
  ) suite_31();

  // Suite 32: Mixed FIFOs (F/X deep, D-intfs medium) + 4x4 lanes
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (32),
    .p_num_fe_lanes          (4),
    .p_num_be_lanes          (4),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (2),
    .p_mul_d_intf_fifo_depth (2),
    .p_mem_d_intf_fifo_depth (2)
  ) suite_32();

  // Suite 33: Deep FIFOs + iterative mul + in-order IQ
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (33),
    .p_muldivrem_sel         (0),
    .p_all_iq_in_order       (1),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4)
  ) suite_33();

  //======================================================================
  // Category G: Sequence Number & Physical Registers (Suites 34-38)
  //======================================================================

  // Suite 34: Tiny seq (ROB=4, 2-bit seq)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (34),
    .p_seq_num_bits  (2),
    .p_num_phys_regs (34)
  ) suite_34();

  // Suite 35: Small seq (ROB=8, 3-bit seq)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (35),
    .p_seq_num_bits  (3),
    .p_num_phys_regs (34)
  ) suite_35();

  // Suite 36: Medium seq + many regs (ROB=16, 50 regs)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (36),
    .p_seq_num_bits  (4),
    .p_num_phys_regs (50)
  ) suite_36();

  // Suite 37: Large seq (ROB=64, 6-bit seq)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (37),
    .p_seq_num_bits  (6),
    .p_num_phys_regs (42)
  ) suite_37();

  // Suite 38: Medium seq + 4 BE lanes (ROB=16, 48 regs)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (38),
    .p_seq_num_bits  (4),
    .p_num_phys_regs (48),
    .p_num_be_lanes  (4)
  ) suite_38();

  //======================================================================
  // Category H: Reclaim Width & Max In-Flight (Suites 39-43)
  //======================================================================

  // Suite 39: Narrow reclaim width (slow seq num freeing)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (39),
    .p_reclaim_width (1)
  ) suite_39();

  // Suite 40: Wide reclaim width (fast seq num freeing)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (40),
    .p_reclaim_width (8)
  ) suite_40();

  // Suite 41: Low max_in_flight (2)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (41),
    .p_max_in_flight (2)
  ) suite_41();

  // Suite 42: High max_in_flight (8)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (42),
    .p_max_in_flight (8)
  ) suite_42();

  // Suite 43: Cross-cut: max_in_flight=3, reclaim=2, 3 FE / 3 BE
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num     (43),
    .p_max_in_flight (3),
    .p_reclaim_width (2),
    .p_num_fe_lanes  (3),
    .p_num_be_lanes  (3)
  ) suite_43();

  //======================================================================
  // Category I: Memory Delays (Suites 44-46)
  //======================================================================

  // Suite 44: Slow memory send (delay=3)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num           (44),
    .p_mem_send_intv_delay (3)
  ) suite_44();

  // Suite 45: Slow memory recv (delay=4)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num           (45),
    .p_mem_recv_intv_delay (4)
  ) suite_45();

  // Suite 46: Both slow + small seq (send=3, recv=3, ROB=8)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num           (46),
    .p_mem_send_intv_delay (3),
    .p_mem_recv_intv_delay (3),
    .p_seq_num_bits        (3)
  ) suite_46();

  //======================================================================
  // Category J: Backpressure (Suites 47-49)
  //======================================================================
  // BP vector layout (4 pipes): {CTRL[3], MEM[2], MUL0[1], ALU0[0]}
  // CTRL byte is always 0 to avoid livelock.

  // Suite 47: F2D backpressure only, 4 FE / 4 BE
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num    (47),
    .p_num_fe_lanes (4),
    .p_num_be_lanes (4),
    .p_sim_f2d_bp   ({8'd3, 8'd5, 8'd3, 8'd7})
  ) suite_47();

  // Suite 48: D2X backpressure (ALU + MUL + MEM, not CTRL)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num  (48),
    .p_sim_d2x_bp ({8'd0, 8'd5, 8'd3, 8'd4})
  ) suite_48();

  // Suite 49: X2W backpressure (ALU + MEM)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num  (49),
    .p_sim_x2w_bp ({8'd0, 8'd4, 8'd0, 8'd3})
  ) suite_49();

  //======================================================================
  // Category K: Stress Combinations (Suites 50-51)
  //======================================================================

  // Suite 50: Multi-exec stress
  //           2 ALU + 2 MUL (6 pipes: ALU0, ALU1, MUL0, MUL1, MEM, CTRL)
  //           4x4 lanes, in-order IQ, iterative mul, deep IQ/FIFOs,
  //           slow mem, combined backpressure
  //           D2X layout: {CTRL=0, MEM=0, MUL1=0, MUL0=3, ALU1=5, ALU0=4}
  //           X2W layout: {CTRL=0, MEM=4, MUL1=0, MUL0=0, ALU1=3, ALU0=0}
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (50),
    .p_num_alus              (2),
    .p_num_muls              (2),
    .p_num_fe_lanes          (4),
    .p_num_be_lanes          (4),
    .p_all_iq_in_order       (1),
    .p_muldivrem_sel         (0),
    .p_iq_depth              (8),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4),
    .p_reclaim_width         (2),
    .p_max_in_flight         (6),
    .p_seq_num_bits          (4),
    .p_mem_send_intv_delay   (2),
    .p_mem_recv_intv_delay   (2),
    .p_sim_f2d_bp            ({8'd5, 8'd3, 8'd7, 8'd4}),
    .p_sim_d2x_bp            ({8'd0, 8'd0, 8'd0, 8'd3, 8'd5, 8'd4}),
    .p_sim_x2w_bp            ({8'd0, 8'd4, 8'd0, 8'd0, 8'd3, 8'd0})
  ) suite_50();

  // Suite 51: Max parallel stress
  //           4 ALU + 2 MUL (8 pipes: ALU0-3, MUL0-1, MEM, CTRL)
  //           4x4 lanes, bypass all pipes, deep IQ/FIFOs,
  //           slow mem, narrow reclaim, high max_in_flight, F2D BP
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (51),
    .p_num_alus              (4),
    .p_num_muls              (2),
    .p_num_fe_lanes          (4),
    .p_num_be_lanes          (4),
    .p_seq_num_bits          (4),
    .p_num_phys_regs         (50),
    .p_pipe_bypass           (1),
    .p_iq_depth              (8),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4),
    .p_reclaim_width         (1),
    .p_max_in_flight         (8),
    .p_mem_send_intv_delay   (3),
    .p_mem_recv_intv_delay   (3),
    .p_sim_f2d_bp            ({8'd3, 8'd5, 8'd3, 8'd4})
  ) suite_51();

  //======================================================================
  // Category L: Branch Prediction (Suites 52-57)
  //======================================================================

  // Suite 52: Branch prediction baseline (2 FE / 2 BE, 64-entry BTB)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num          (52),
    .p_enable_branch_pred (1)
  ) suite_52();

  // Suite 53: Branch prediction, single-lane (1 FE / 1 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num          (53),
    .p_enable_branch_pred (1),
    .p_num_fe_lanes       (1),
    .p_num_be_lanes       (1)
  ) suite_53();

  // Suite 54: Branch prediction, wide (4 FE / 4 BE)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num          (54),
    .p_enable_branch_pred (1),
    .p_num_fe_lanes       (4),
    .p_num_be_lanes       (4)
  ) suite_54();

  // Suite 55: Branch prediction, small BTB (16 entries)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num          (55),
    .p_enable_branch_pred (1),
    .p_btb_entries        (16)
  ) suite_55();

  // Suite 56: Branch prediction, large BTB (256 entries)
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num          (56),
    .p_enable_branch_pred (1),
    .p_btb_entries        (256)
  ) suite_56();

  // Suite 57: Branch prediction + multi-exec stress
  //           2 ALU + 2 MUL, 4x4, in-order IQ, deep FIFOs
  `ZEPPELIN_SUITE_MODULE #(
    .p_suite_num             (57),
    .p_enable_branch_pred    (1),
    .p_num_alus              (2),
    .p_num_muls              (2),
    .p_num_fe_lanes          (4),
    .p_num_be_lanes          (4),
    .p_all_iq_in_order       (1),
    .p_iq_depth              (8),
    .p_f_intf_fifo_depth     (4),
    .p_x_intf_fifo_depth     (4),
    .p_alu_d_intf_fifo_depth (4),
    .p_mul_d_intf_fifo_depth (4),
    .p_mem_d_intf_fifo_depth (4)
  ) suite_57();

  //======================================================================
  // Test Suite Runner
  //======================================================================

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
    if ((s <= 0) || (s == 13)) suite_13.run_test_suite();
    if ((s <= 0) || (s == 14)) suite_14.run_test_suite();
    if ((s <= 0) || (s == 15)) suite_15.run_test_suite();
    if ((s <= 0) || (s == 16)) suite_16.run_test_suite();
    if ((s <= 0) || (s == 17)) suite_17.run_test_suite();
    if ((s <= 0) || (s == 18)) suite_18.run_test_suite();
    if ((s <= 0) || (s == 19)) suite_19.run_test_suite();
    if ((s <= 0) || (s == 20)) suite_20.run_test_suite();
    if ((s <= 0) || (s == 21)) suite_21.run_test_suite();
    if ((s <= 0) || (s == 22)) suite_22.run_test_suite();
    if ((s <= 0) || (s == 23)) suite_23.run_test_suite();
    if ((s <= 0) || (s == 24)) suite_24.run_test_suite();
    if ((s <= 0) || (s == 25)) suite_25.run_test_suite();
    if ((s <= 0) || (s == 26)) suite_26.run_test_suite();
    if ((s <= 0) || (s == 27)) suite_27.run_test_suite();
    if ((s <= 0) || (s == 28)) suite_28.run_test_suite();
    if ((s <= 0) || (s == 29)) suite_29.run_test_suite();
    if ((s <= 0) || (s == 30)) suite_30.run_test_suite();
    if ((s <= 0) || (s == 31)) suite_31.run_test_suite();
    if ((s <= 0) || (s == 32)) suite_32.run_test_suite();
    if ((s <= 0) || (s == 33)) suite_33.run_test_suite();
    if ((s <= 0) || (s == 34)) suite_34.run_test_suite();
    if ((s <= 0) || (s == 35)) suite_35.run_test_suite();
    if ((s <= 0) || (s == 36)) suite_36.run_test_suite();
    if ((s <= 0) || (s == 37)) suite_37.run_test_suite();
    if ((s <= 0) || (s == 38)) suite_38.run_test_suite();
    if ((s <= 0) || (s == 39)) suite_39.run_test_suite();
    if ((s <= 0) || (s == 40)) suite_40.run_test_suite();
    if ((s <= 0) || (s == 41)) suite_41.run_test_suite();
    if ((s <= 0) || (s == 42)) suite_42.run_test_suite();
    if ((s <= 0) || (s == 43)) suite_43.run_test_suite();
    if ((s <= 0) || (s == 44)) suite_44.run_test_suite();
    if ((s <= 0) || (s == 45)) suite_45.run_test_suite();
    if ((s <= 0) || (s == 46)) suite_46.run_test_suite();
    if ((s <= 0) || (s == 47)) suite_47.run_test_suite();
    if ((s <= 0) || (s == 48)) suite_48.run_test_suite();
    if ((s <= 0) || (s == 49)) suite_49.run_test_suite();
    if ((s <= 0) || (s == 50)) suite_50.run_test_suite();
    if ((s <= 0) || (s == 51)) suite_51.run_test_suite();
    if ((s <= 0) || (s == 52)) suite_52.run_test_suite();
    if ((s <= 0) || (s == 53)) suite_53.run_test_suite();
    if ((s <= 0) || (s == 54)) suite_54.run_test_suite();
    if ((s <= 0) || (s == 55)) suite_55.run_test_suite();
    if ((s <= 0) || (s == 56)) suite_56.run_test_suite();
    if ((s <= 0) || (s == 57)) suite_57.run_test_suite();

    test_bench_end();
  end

`undef ZEPPELIN_SUITE_MODULE
`endif
