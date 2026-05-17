//========================================================================
// Zeppelin_sltu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sltu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sltu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sltu)
endmodule

module Zeppelin_sltu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sltu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
