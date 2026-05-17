//========================================================================
// FLProc_test.v
//========================================================================

`include "hw/top/test/FLProcTestHarness.v"

module FLProc_test #();
  FLProcTestHarness h();

  //----------------------------------------------------------------------
  // Include test cases
  //----------------------------------------------------------------------

  `include "hw/top/test/test_cases/directed/addi_test_cases.v"
  `include "hw/top/test/test_cases/directed/add_test_cases.v"
  `include "hw/top/test/test_cases/directed/lw_test_cases.v"
  `include "hw/top/test/test_cases/directed/sw_test_cases.v"
  `include "hw/top/test/test_cases/directed/jal_test_cases.v"
  `include "hw/top/test/test_cases/directed/jalr_test_cases.v"
  `include "hw/top/test/test_cases/directed/bne_test_cases.v"

  `include "hw/top/test/test_cases/directed/sub_test_cases.v"
  `include "hw/top/test/test_cases/directed/and_test_cases.v"
  `include "hw/top/test/test_cases/directed/or_test_cases.v"
  `include "hw/top/test/test_cases/directed/xor_test_cases.v"
  `include "hw/top/test/test_cases/directed/slt_test_cases.v"
  `include "hw/top/test/test_cases/directed/sltu_test_cases.v"
  `include "hw/top/test/test_cases/directed/sra_test_cases.v"
  `include "hw/top/test/test_cases/directed/srl_test_cases.v"
  `include "hw/top/test/test_cases/directed/sll_test_cases.v"

  `include "hw/top/test/test_cases/directed/andi_test_cases.v"
  `include "hw/top/test/test_cases/directed/ori_test_cases.v"
  `include "hw/top/test/test_cases/directed/xori_test_cases.v"
  `include "hw/top/test/test_cases/directed/slti_test_cases.v"
  `include "hw/top/test/test_cases/directed/sltiu_test_cases.v"
  `include "hw/top/test/test_cases/directed/srai_test_cases.v"
  `include "hw/top/test/test_cases/directed/srli_test_cases.v"
  `include "hw/top/test/test_cases/directed/slli_test_cases.v"
  `include "hw/top/test/test_cases/directed/lui_test_cases.v"
  `include "hw/top/test/test_cases/directed/auipc_test_cases.v"

  `include "hw/top/test/test_cases/directed/lb_test_cases.v"
  `include "hw/top/test/test_cases/directed/lh_test_cases.v"
  `include "hw/top/test/test_cases/directed/lbu_test_cases.v"
  `include "hw/top/test/test_cases/directed/lhu_test_cases.v"
  `include "hw/top/test/test_cases/directed/sb_test_cases.v"
  `include "hw/top/test/test_cases/directed/sh_test_cases.v"

  `include "hw/top/test/test_cases/directed/beq_test_cases.v"
  `include "hw/top/test/test_cases/directed/blt_test_cases.v"
  `include "hw/top/test/test_cases/directed/bge_test_cases.v"
  `include "hw/top/test/test_cases/directed/bltu_test_cases.v"
  `include "hw/top/test/test_cases/directed/bgeu_test_cases.v"

  `include "hw/top/test/test_cases/directed/fence_test_cases.v"

  `include "hw/top/test/test_cases/directed/mul_test_cases.v"
  `include "hw/top/test/test_cases/directed/mulh_test_cases.v"
  `include "hw/top/test/test_cases/directed/mulhu_test_cases.v"
  `include "hw/top/test/test_cases/directed/mulhsu_test_cases.v"
  `include "hw/top/test/test_cases/directed/div_test_cases.v"
  `include "hw/top/test/test_cases/directed/divu_test_cases.v"
  `include "hw/top/test/test_cases/directed/rem_test_cases.v"
  `include "hw/top/test/test_cases/directed/remu_test_cases.v"

  //----------------------------------------------------------------------
  // run_tests
  //----------------------------------------------------------------------

  task run_tests();
    test_bench_begin( `__FILE__ );

    h.t.test_suite_begin( "FLProc_test" );
    run_directed_addi_tests();
    run_directed_add_tests();
    run_directed_lw_tests();
    run_directed_sw_tests();
    run_directed_jal_tests();
    run_directed_jalr_tests();
    run_directed_bne_tests();

    run_directed_sub_tests();
    run_directed_and_tests();
    run_directed_or_tests();
    run_directed_xor_tests();
    run_directed_slt_tests();
    run_directed_sltu_tests();
    run_directed_sra_tests();
    run_directed_srl_tests();
    run_directed_sll_tests();

    run_directed_andi_tests();
    run_directed_ori_tests();
    run_directed_xori_tests();
    run_directed_slti_tests();
    run_directed_sltiu_tests();
    run_directed_srai_tests();
    run_directed_srli_tests();
    run_directed_slli_tests();
    run_directed_lui_tests();
    run_directed_auipc_tests();

    run_directed_lb_tests();
    run_directed_lh_tests();
    run_directed_lbu_tests();
    run_directed_lhu_tests();
    run_directed_sb_tests();
    run_directed_sh_tests();

    run_directed_beq_tests();
    run_directed_blt_tests();
    run_directed_bge_tests();
    run_directed_bltu_tests();
    run_directed_bgeu_tests();

    run_directed_fence_tests();

    run_directed_mul_tests();
    run_directed_mulh_tests();
    run_directed_mulhu_tests();
    run_directed_mulhsu_tests();
    run_directed_div_tests();
    run_directed_divu_tests();
    run_directed_rem_tests();
    run_directed_remu_tests();

    test_bench_end();
  endtask
  
  initial run_tests();
endmodule
