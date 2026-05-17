//========================================================================
// Zeppelin_srli_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_srli #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/srli_test_cases.v"
  `ZEPPELIN_SUITE_RUN(srli)
endmodule

module Zeppelin_srli_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_srli
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
