//========================================================================
// Zeppelin_add_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_add #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/add_test_cases.v"
  `include "hw/top/test/test_cases/golden/add_test_cases.v"
  `ZEPPELIN_SUITE_RUN(add, run_golden_add_tests();)
endmodule

module Zeppelin_add_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_add
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
