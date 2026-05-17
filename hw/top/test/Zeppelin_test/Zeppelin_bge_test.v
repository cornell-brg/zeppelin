//========================================================================
// Zeppelin_bge_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_bge #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/bge_test_cases.v"
  `ZEPPELIN_SUITE_RUN(bge)
endmodule

module Zeppelin_bge_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_bge
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
