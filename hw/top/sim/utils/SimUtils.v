//========================================================================
// SimUtils.v
//========================================================================
// Simulation utilities, to be used in processor simulations

`ifndef HW_TOP_SIM_SIM_UTILS_V
`define HW_TOP_SIM_SIM_UTILS_V

//------------------------------------------------------------------------
// Colors
//------------------------------------------------------------------------

`define RED    "\033[31m"
`define YELLOW "\033[33m"
`define GREEN  "\033[32m"
`define BLUE   "\033[34m"
`define PURPLE "\033[35m"
`define RESET  "\033[0m"

//------------------------------------------------------------------------
// Cycle Time
//------------------------------------------------------------------------

`ifndef CYCLE_TIME
  `define CYCLE_TIME 10
`endif

//------------------------------------------------------------------------
// SimUtils
//------------------------------------------------------------------------

module SimUtils
(
  output logic clk,
  output logic rst
);

  // ---------------------------------------------------------------------
  // Clocking
  // ---------------------------------------------------------------------
  
  // verilator lint_off BLKSEQ
  initial clk = 1'b1;
  always #(`CYCLE_TIME/2) clk = ~clk;
  // verilator lint_on BLKSEQ

  // ---------------------------------------------------------------------
  // Filtering Utilities
  // ---------------------------------------------------------------------

  // verilator lint_off UNUSEDSIGNAL
  logic  verbose;
  int    trace_level;
  string trace_header;
  // verilator lint_on UNUSEDSIGNAL

  initial begin
    if ( $test$plusargs ("verbose") || $test$plusargs ("v") )
      verbose = 1'b1;
    else
      verbose = 1'b0;

    if ( !$value$plusargs( "trace-level=%d", trace_level ) )
      trace_level = 0;
  end

  string elf_file;
  initial begin
    if( !$value$plusargs( "elf=%s", elf_file ) )
      $fatal(0, "No ELF file specified with +elf=/path/to/elf" );
  end

  // ---------------------------------------------------------------------
  // Waveform Dumping
  // ---------------------------------------------------------------------

  string filename;
  initial begin
    if ( $value$plusargs( "dump-vcd=%s", filename ) ) begin
      $dumpfile(filename);
      $dumpvars();
    end
  end

  int    inst_trace_fd;
  logic  dump_inst_traces;
  string inst_trace_filename;
  initial begin
    if ( $value$plusargs( "dump-inst-traces=%s", inst_trace_filename ) ) begin
      inst_trace_fd    = $fopen (inst_trace_filename, "w");
      dump_inst_traces = 1'b1;
    end else begin
      dump_inst_traces = 1'b0;
    end
  end

  int    line_trace_fd;
  logic  dump_line_traces;
  string line_trace_filename;
  initial begin
    if ( $value$plusargs( "dump-line-traces=%s", line_trace_filename ) ) begin
      line_trace_fd    = $fopen (line_trace_filename, "w");
      dump_line_traces = 1'b1;
    end else begin
      dump_line_traces = 1'b0;
    end
  end

  // ---------------------------------------------------------------------
  // Timeout
  // ---------------------------------------------------------------------

  int   cycles;
  int   timeout     = 10000;
  logic timeout_val = 1'b0;

  initial begin
    if( $value$plusargs( "timeout=%d", timeout ) )
      timeout_val = 1'b1;
  end

  always @( posedge clk ) begin

    if ( rst )
      cycles <= 0;
    else
      cycles <= cycles + 1;

    if ( timeout_val & ( cycles > timeout ) ) begin
      $write("\n");
      // $fatal("ERROR (cycles=%0d): timeout!", cycles );
      $finish;
    end

  end

  // ---------------------------------------------------------------------
  // Random Seeding
  // ---------------------------------------------------------------------

  // Seed random test cases
  int seed = 32'hdeadbeef;
  initial seed = $urandom(seed);

  task sim_begin();
    rst = 1'b1;
    for( int i = 0; i < 3; i = i + 1 ) begin
      @(posedge clk);
    end
    `ifndef BAGLSIM
    #1;
    `else
    #(`INPUT_DELAY);
    `endif
    rst = 1'b0;

    if ( trace_header.len() > 0 ) begin
      if ( dump_line_traces )
        $fdisplay( line_trace_fd, trace_header );
      if ( verbose )
        $display( trace_header );
    end
  endtask

  //----------------------------------------------------------------------
  // trace
  //----------------------------------------------------------------------

  task trace( string msg_to_trace );
    if( !rst ) begin
      if( dump_line_traces )
        $fdisplay( line_trace_fd, msg_to_trace );
      if( verbose )
        $display( msg_to_trace );
    end
  endtask

  //----------------------------------------------------------------------
  // inst_trace
  //----------------------------------------------------------------------

  task inst_trace(
    input logic [31:0] pc,
    input logic  [4:0] waddr,
    input logic [31:0] wdata,
    input logic        wen
  );
    if( dump_inst_traces ) begin
      $fwrite(inst_trace_fd, "0x%08x: ", pc);
      if( wen ) begin
        $fwrite(inst_trace_fd, "0x%08x -> R[%0d]",
          wdata,
          waddr
        );
      end
      $fdisplay(inst_trace_fd, "");
    end
  endtask

  //----------------------------------------------------------------------
  // CPI Calculator
  //----------------------------------------------------------------------

  int num_committed = 0;

  task commit_notify( input int num_insts );
    num_committed = num_committed + num_insts;
  endtask

  final begin
    if( num_committed > 0 ) begin
      $display( "" );
      $display( "Raw CPI = %0d / %0d = %f",
        cycles, num_committed, real'(cycles) / real'(num_committed) );
    end
  end

endmodule

`endif // HW_TOP_SIM_SIM_UTILS_V
