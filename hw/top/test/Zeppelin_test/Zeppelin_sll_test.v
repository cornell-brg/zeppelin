//========================================================================
// Zeppelin_sll_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sll #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sll_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sll)
endmodule

module Zeppelin_sll_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sll
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
