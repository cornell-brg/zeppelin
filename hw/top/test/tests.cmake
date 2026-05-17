# ========================================================================
# tests.cmake
# ========================================================================
# Identify all of Zeppelin's sub-tests

set(PROCS
  FLProc
  Zeppelin
)

# ------------------------------------------------------------------------
# FLProc
# ------------------------------------------------------------------------

set(FLProc_TESTS
  FLProc_test/FLProc_test.v
)

# ------------------------------------------------------------------------
# Zeppelin
# ------------------------------------------------------------------------

set(Zeppelin_TESTS
  Zeppelin_test/Zeppelin_add_test.v
  Zeppelin_test/Zeppelin_addi_test.v
  Zeppelin_test/Zeppelin_lw_test.v
  Zeppelin_test/Zeppelin_sw_test.v
  Zeppelin_test/Zeppelin_jal_test.v
  Zeppelin_test/Zeppelin_jalr_test.v
  Zeppelin_test/Zeppelin_bne_test.v

  Zeppelin_test/Zeppelin_sub_test.v
  Zeppelin_test/Zeppelin_and_test.v
  Zeppelin_test/Zeppelin_or_test.v
  Zeppelin_test/Zeppelin_xor_test.v
  Zeppelin_test/Zeppelin_slt_test.v
  Zeppelin_test/Zeppelin_sltu_test.v
  Zeppelin_test/Zeppelin_sra_test.v
  Zeppelin_test/Zeppelin_srl_test.v
  Zeppelin_test/Zeppelin_sll_test.v

  Zeppelin_test/Zeppelin_andi_test.v
  Zeppelin_test/Zeppelin_ori_test.v
  Zeppelin_test/Zeppelin_xori_test.v
  Zeppelin_test/Zeppelin_slti_test.v
  Zeppelin_test/Zeppelin_sltiu_test.v
  Zeppelin_test/Zeppelin_srai_test.v
  Zeppelin_test/Zeppelin_srli_test.v
  Zeppelin_test/Zeppelin_slli_test.v
  Zeppelin_test/Zeppelin_lui_test.v
  Zeppelin_test/Zeppelin_auipc_test.v

  Zeppelin_test/Zeppelin_beq_test.v
  Zeppelin_test/Zeppelin_blt_test.v
  Zeppelin_test/Zeppelin_bge_test.v
  Zeppelin_test/Zeppelin_bltu_test.v
  Zeppelin_test/Zeppelin_bgeu_test.v

  Zeppelin_test/Zeppelin_lb_test.v
  Zeppelin_test/Zeppelin_lh_test.v
  Zeppelin_test/Zeppelin_lbu_test.v
  Zeppelin_test/Zeppelin_lhu_test.v
  Zeppelin_test/Zeppelin_sb_test.v
  Zeppelin_test/Zeppelin_sh_test.v
  Zeppelin_test/Zeppelin_fence_test.v

  Zeppelin_test/Zeppelin_mul_test.v
  Zeppelin_test/Zeppelin_mulh_test.v
  Zeppelin_test/Zeppelin_mulhu_test.v
  Zeppelin_test/Zeppelin_mulhsu_test.v
  Zeppelin_test/Zeppelin_div_test.v
  Zeppelin_test/Zeppelin_divu_test.v
  Zeppelin_test/Zeppelin_rem_test.v
  Zeppelin_test/Zeppelin_remu_test.v

  Zeppelin_test/Zeppelin_mixed_test.v
)
