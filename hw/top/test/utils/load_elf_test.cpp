//========================================================================
// load_elf.cpp
//========================================================================
// A C++ interface to load an ELF file into memory for testing purposes

#include "fl/parse_elf.h"
#include "fl/fl_vtrace.h"
#include "svdpi.h"
#include <cstdint>

extern "C" void init_dut_mem( const svBitVecVal* addr,
                              const svBitVecVal* data );

//------------------------------------------------------------------------
// init_fl_and_dut_mem
//------------------------------------------------------------------------
// A helper function to initialize the FL & DUT processor memories

void init_fl_and_dut_mem( uint32_t addr, uint32_t data )
{
  init_dut_mem( &addr, &data );
  fl_init( &addr, &data );
}

//------------------------------------------------------------------------
// load_elf_test
//------------------------------------------------------------------------

extern "C" void load_elf_test( const char* elf_file )
{
  parse_elf( elf_file, init_fl_and_dut_mem );
}
