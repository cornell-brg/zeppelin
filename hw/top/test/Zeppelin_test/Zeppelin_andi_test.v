//========================================================================
// Zeppelin_andi_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_andi #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/andi_test_cases.v"
  `ZEPPELIN_SUITE_RUN(andi)
endmodule

module Zeppelin_andi_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_andi
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
