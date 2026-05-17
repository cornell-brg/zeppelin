//========================================================================
// Zeppelin_mulhu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_mulhu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/mulhu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(mulhu)
endmodule

module Zeppelin_mulhu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_mulhu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
