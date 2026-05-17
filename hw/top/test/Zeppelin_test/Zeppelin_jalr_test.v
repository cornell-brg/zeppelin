//========================================================================
// Zeppelin_jalr_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_jalr #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/jalr_test_cases.v"
  `include "hw/top/test/test_cases/golden/jalr_test_cases.v"
  `ZEPPELIN_SUITE_RUN(jalr, run_golden_jalr_tests();)
endmodule

module Zeppelin_jalr_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_jalr
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
