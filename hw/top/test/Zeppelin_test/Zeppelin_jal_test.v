//========================================================================
// Zeppelin_jal_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_jal #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/jal_test_cases.v"
  `include "hw/top/test/test_cases/golden/jal_test_cases.v"
  `ZEPPELIN_SUITE_RUN(jal, run_golden_jal_tests();)
endmodule

module Zeppelin_jal_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_jal
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
