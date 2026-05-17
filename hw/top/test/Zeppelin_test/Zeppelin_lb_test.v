//========================================================================
// Zeppelin_lb_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_lb #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/lb_test_cases.v"
  `ZEPPELIN_SUITE_RUN(lb)
endmodule

module Zeppelin_lb_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_lb
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
