//========================================================================
// Zeppelin_slli_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_slli #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/slli_test_cases.v"
  `ZEPPELIN_SUITE_RUN(slli)
endmodule

module Zeppelin_slli_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_slli
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
