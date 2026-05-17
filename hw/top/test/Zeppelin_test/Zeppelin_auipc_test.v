//========================================================================
// Zeppelin_auipc_test.v
//========================================================================

`include "hw/top/test/ZeppelinTestHarness.v"
`include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"

module ZeppelinTestSuite_auipc #( `ZEPPELIN_SUITE_PARAMS );
  `ZEPPELIN_SUITE_HARNESS

  `include "hw/top/test/test_cases/directed/auipc_test_cases.v"
  `ZEPPELIN_SUITE_RUN(auipc)
endmodule

module Zeppelin_auipc_test;
  `define ZEPPELIN_SUITE_MODULE ZeppelinTestSuite_auipc
  `include "hw/top/test/Zeppelin_test/Zeppelin_test_suites.vh"
endmodule
