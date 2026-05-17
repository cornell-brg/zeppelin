//========================================================================
// Zeppelin_mulh_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_mulh #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/mulh_test_cases.v"
  `ZEPPELIN_SUITE_RUN(mulh)
endmodule

module Zeppelin_mulh_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_mulh
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
