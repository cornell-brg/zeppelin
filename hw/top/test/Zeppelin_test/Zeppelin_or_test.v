//========================================================================
// Zeppelin_or_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_or #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/or_test_cases.v"
  `ZEPPELIN_SUITE_RUN(or)
endmodule

module Zeppelin_or_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_or
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
