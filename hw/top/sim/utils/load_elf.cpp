// =======================================================================
// load_elf.cpp
// =======================================================================
// A C++ interface to load an ELF file into memory

#include "fl/parse_elf.h"
#include "svdpi.h"
#include <cstdint>

extern "C" void init_mem( const svBitVecVal* addr,
                          const svBitVecVal* data );

//------------------------------------------------------------------------
// init_proc_mem
//------------------------------------------------------------------------
// A helper function to initialize the processor memory

void init_proc_mem( uint32_t addr, uint32_t data )
{
  init_mem( &addr, &data );
}

//------------------------------------------------------------------------
// load_elf
//------------------------------------------------------------------------

extern "C" void load_elf( const char* elf_file )
{
  parse_elf( elf_file, init_proc_mem );
}