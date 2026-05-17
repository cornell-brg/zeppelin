// =======================================================================
// sim.cpp
// =======================================================================
// A basic simulator for running testbenches

// Include common routines
#include <verilated.h>

// Include model header (ex. Vtop.h)
#include VERILATOR_INCL_HEADER

#define RED "\033[31m"
#define RESET "\033[0m"

// -----------------------------------------------------------------------
// vl_fatal
// -----------------------------------------------------------------------
// Called from Verilog in Verilator with $fatal, overriden by compiling
// with -DVL_USER_FATAL

extern void vl_fatal( const char* filename, int linenum, const char* hier,
                      const char* msg )
{
  // We don't currently use the filename, line number, or level
  (void) filename;
  (void) linenum;
  (void) hier;

  // Signal to the model that we got a fatal message
  Verilated::threadContextp()->gotError( true );
  Verilated::threadContextp()->gotFinish( true );

  // Print the message
  VL_PRINTF( "%s[ERROR]%s %s\n", RED, RESET, msg );
  Verilated::runFlushCallbacks();

  // Exit
  Verilated::runExitCallbacks();
  exit( 1 );
}

// -----------------------------------------------------------------------
// vl_finish
// -----------------------------------------------------------------------
// Called from Verilog in Verilator with $finish, overriden by compiling
// with -DVL_USER_FATAL

extern void vl_finish( const char* filename, int linenum,
                       const char* hier )
{
  // We don't currently use the filename or line number
  (void) filename;
  (void) linenum;

  // Signal to the model that we've finished
  Verilated::threadContextp()->gotFinish( true );
}

// -----------------------------------------------------------------------
// main
// -----------------------------------------------------------------------

int main( int argc, char** argv )
{
  // Construct a VerilatedContext to hold simulation time, etc.
  VerilatedContext* const contextp = new VerilatedContext;

  // Verilator must compute traced signals
  contextp->traceEverOn( true );

  // Pass arguments so Verilated code can see them, e.g. $value$plusargs
  // This needs to be called before you create any model
  contextp->commandArgs( argc, argv );

  // Construct the Verilated model, from Vtop.h generated from Verilating
  // "top.v"
  VERILATOR_TOP_MODULE* top = new VERILATOR_TOP_MODULE{ contextp };

  // Simulate until $finish
  while ( !contextp->gotFinish() ) {
    // Increment time
    contextp->timeInc( 1 );
    // Evaluate model
    top->eval();
  }

  // Final model cleanup
  top->final();

#if VM_COVERAGE
  Verilated::mkdir( "logs" );
  contextp->coveragep()->write( "logs/coverage.dat" );
#endif

  // Destroy model
  delete top;

  // Return good completion status
  return 0;
}