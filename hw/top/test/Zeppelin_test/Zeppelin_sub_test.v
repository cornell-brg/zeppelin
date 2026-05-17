//========================================================================
// Zeppelin_sub_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sub #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sub_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sub)
endmodule

module Zeppelin_sub_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sub
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
