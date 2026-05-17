//========================================================================
// Zeppelin_slti_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_slti #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/slti_test_cases.v"
  `ZEPPELIN_SUITE_RUN(slti)
endmodule

module Zeppelin_slti_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_slti
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
