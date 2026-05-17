//========================================================================
// rvelfdump.cpp
//========================================================================
// A script to dump the necessary data to program Zeppelin on an FPGA
//
// The map file will contain an address: data mapping on each line
// Ex. deadbeef: cafecafe

#include "asm/disassemble.h"
#include "fl/parse_elf.h"
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>

std::ofstream dump_file;

//------------------------------------------------------------------------
// dump_map
//------------------------------------------------------------------------
// Dump a single address: data map to the file

void dump_map( uint32_t addr, uint32_t data )
{
  dump_file << std::hex << std::setw( 8 ) << std::setfill( '0' ) << addr
            << ": " << std::hex << std::setw( 8 ) << std::setfill( '0' )
            << data << "    # " << disassemble( &data, &addr )
            << std::endl;
}

//------------------------------------------------------------------------
// dump_prologue
//------------------------------------------------------------------------
// Dump a prologue indicating what the map is for

void dump_prologue( std::string file_path )
{
  dump_file
      << "# ========================================================================"
      << std::endl;
  dump_file << "# " << "Memory Map of "
            << std::filesystem::absolute( file_path ) << std::endl;
  dump_file
      << "# ========================================================================"
      << std::endl
      << std::endl;
}

//------------------------------------------------------------------------
// main
//------------------------------------------------------------------------

int main( int argc, char* argv[] )
{
  if ( argc != 3 ) {
    std::cout << "Usage: " << argv[0] << " elf_file map.txt" << std::endl;
    exit( 1 );
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Open the map file
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  dump_file.open( argv[2] );
  if ( !dump_file.is_open() ) {
    std::cout << "Error opening output file: " << argv[2] << std::endl;
    exit( 1 );
  }
  dump_prologue( argv[1] );

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  // Parse the ELF file
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  parse_elf( argv[1], dump_map );
  dump_file.close();
  return 0;
}