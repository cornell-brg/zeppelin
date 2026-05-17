//========================================================================
// Zeppelin_lbu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_lbu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/lbu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(lbu)
endmodule

module Zeppelin_lbu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_lbu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
