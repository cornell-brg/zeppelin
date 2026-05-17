//========================================================================
// Zeppelin_lw_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_lw #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/lw_test_cases.v"
  `include "hw/top/test/test_cases/golden/lw_test_cases.v"
  `ZEPPELIN_SUITE_RUN(lw, run_golden_lw_tests();)
endmodule

module Zeppelin_lw_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_lw
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
