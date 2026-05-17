//========================================================================
// Zeppelin_sh_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sh #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sh_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sh)
endmodule

module Zeppelin_sh_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sh
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
