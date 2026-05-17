//========================================================================
// Zeppelin_rem_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_rem #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/rem_test_cases.v"
  `ZEPPELIN_SUITE_RUN(rem)
endmodule

module Zeppelin_rem_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_rem
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
