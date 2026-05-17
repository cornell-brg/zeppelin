//========================================================================
// Zeppelin_xori_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_xori #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/xori_test_cases.v"
  `ZEPPELIN_SUITE_RUN(xori)
endmodule

module Zeppelin_xori_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_xori
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
