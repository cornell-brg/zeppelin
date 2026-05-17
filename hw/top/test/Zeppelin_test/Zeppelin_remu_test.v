//========================================================================
// Zeppelin_remu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_remu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/remu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(remu)
endmodule

module Zeppelin_remu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_remu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
