//========================================================================
// Zeppelin_lui_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_lui #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/lui_test_cases.v"
  `ZEPPELIN_SUITE_RUN(lui)
endmodule

module Zeppelin_lui_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_lui
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
