//========================================================================
// Zeppelin_srai_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_srai #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/srai_test_cases.v"
  `ZEPPELIN_SUITE_RUN(srai)
endmodule

module Zeppelin_srai_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_srai
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
