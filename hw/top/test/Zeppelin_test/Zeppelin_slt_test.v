//========================================================================
// Zeppelin_slt_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_slt #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/slt_test_cases.v"
  `ZEPPELIN_SUITE_RUN(slt)
endmodule

module Zeppelin_slt_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_slt
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
