//========================================================================
// Zeppelin_bltu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_bltu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/bltu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(bltu)
endmodule

module Zeppelin_bltu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_bltu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
