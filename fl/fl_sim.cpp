//========================================================================
// fl_sim.cpp
//========================================================================
// A top-level program for simulating a RISCV binary with the FLProc

#include "fl/FLProc.h"
#include "fl/parse_elf.h"
#include <fstream>
#include <iomanip>
#include <iostream>

// -----------------------------------------------------------------------
// Instantiate processor
// -----------------------------------------------------------------------

FLProc proc;

void init_mem( uint32_t addr, uint32_t data )
{
  proc.init( addr, data );
}

// -----------------------------------------------------------------------
// main
// -----------------------------------------------------------------------

int main( int argc, char* argv[] )
{
  if ( ( argc < 2 ) | ( argc > 3 ) ) {
    std::cout << "Usage: " << argv[0]
              << " elf_file [--dump-trace=/path/to/file.trace]"
              << std::endl;
    exit( 1 );
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Check for tracing
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  bool          trace = false;
  char          file_path[50];
  std::ofstream dump_file;
  for ( int i = 1; i < argc; i++ ) {
    if ( sscanf( argv[i], "--dump-trace=%s", file_path ) ) {
      trace = true;
      dump_file.open( file_path );
      if ( !dump_file.is_open() ) {
        printf( "Error: Couldn't open dump file '%s'", file_path );
        exit( 1 );
      }
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Add the data from the ELF file
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  parse_elf( argv[1], init_mem );

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Simulate the design
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  while ( 1 ) {
    FLTrace inst_trace = proc.step();
    if ( trace ) {
      dump_file << inst_trace << std::endl;
    }
  }
}