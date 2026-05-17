//========================================================================
// Zeppelin_sw_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_sw #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/sw_test_cases.v"
  `include "hw/top/test/test_cases/golden/sw_test_cases.v"
  `ZEPPELIN_SUITE_RUN(sw, run_golden_sw_tests();)
endmodule

module Zeppelin_sw_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_sw
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
