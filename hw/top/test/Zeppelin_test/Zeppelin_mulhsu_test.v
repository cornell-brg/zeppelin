//========================================================================
// Zeppelin_mulhsu_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_mulhsu #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/mulhsu_test_cases.v"
  `ZEPPELIN_SUITE_RUN(mulhsu)
endmodule

module Zeppelin_mulhsu_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_mulhsu
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
