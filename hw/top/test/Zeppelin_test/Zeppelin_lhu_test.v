//========================================================================
// Zeppelin_lhu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_lhu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/lhu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(lhu)
endmodule

module Zeppelin_lhu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_lhu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
