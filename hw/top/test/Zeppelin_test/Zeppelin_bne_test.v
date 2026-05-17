//========================================================================
// Zeppelin_bne_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_bne #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/bne_test_cases.v"
  `include "hw/top/test/test_cases/golden/bne_test_cases.v"
  `ZEPPELIN_SUITE_RUN(bne, run_golden_bne_tests();)
endmodule

module Zeppelin_bne_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_bne
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
