//========================================================================
// Zeppelin_bgeu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_bgeu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/bgeu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(bgeu)
endmodule

module Zeppelin_bgeu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_bgeu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
