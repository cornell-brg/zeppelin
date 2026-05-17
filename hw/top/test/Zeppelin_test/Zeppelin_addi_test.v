//========================================================================
// Zeppelin_addi_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_addi #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/addi_test_cases.v"
  `include "hw/top/test/test_cases/golden/addi_test_cases.v"
  `ZEPPELIN_SUITE_RUN(addi, run_golden_addi_tests();)
endmodule

module Zeppelin_addi_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_addi
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
