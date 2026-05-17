//========================================================================
// Zeppelin_and_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_and #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/and_test_cases.v"
  `ZEPPELIN_SUITE_RUN(and)
endmodule

module Zeppelin_and_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_and
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
