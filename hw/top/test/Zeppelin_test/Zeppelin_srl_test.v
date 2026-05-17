//========================================================================
// Zeppelin_srl_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_srl #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/srl_test_cases.v"
  `ZEPPELIN_SUITE_RUN(srl)
endmodule

module Zeppelin_srl_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_srl
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
