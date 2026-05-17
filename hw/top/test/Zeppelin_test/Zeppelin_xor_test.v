//========================================================================
// Zeppelin_xor_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_xor #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/xor_test_cases.v"
  `ZEPPELIN_SUITE_RUN(xor)
endmodule

module Zeppelin_xor_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_xor
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
