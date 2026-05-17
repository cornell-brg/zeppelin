//========================================================================
// Zeppelin_blt_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_blt #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/blt_test_cases.v"
  `ZEPPELIN_SUITE_RUN(blt)
endmodule

module Zeppelin_blt_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_blt
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
