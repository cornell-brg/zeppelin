//========================================================================
// Zeppelin_lh_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_lh #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/lh_test_cases.v"
  `ZEPPELIN_SUITE_RUN(lh)
endmodule

module Zeppelin_lh_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_lh
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
