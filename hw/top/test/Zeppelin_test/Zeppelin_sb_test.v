//========================================================================
// Zeppelin_sb_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sb #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sb_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sb)
endmodule

module Zeppelin_sb_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sb
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
