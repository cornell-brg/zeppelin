//========================================================================
// Zeppelin_div_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_div #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/div_test_cases.v"
  `ZEPPELIN_SUITE_RUN(div)
endmodule

module Zeppelin_div_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_div
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
