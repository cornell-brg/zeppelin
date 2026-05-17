//========================================================================
// FLTerminal.cpp
//========================================================================
// A memory-mapped peripheral for getting user input

#include "fl/peripherals/FLTerminal.h"
#include <iostream>

//------------------------------------------------------------------------
// read
//------------------------------------------------------------------------

static std::string stdin_buffer = "";

void FLTerminal::read( uint32_t addr, uint32_t* data )
{
  // Unused address
  (void) addr;

  // Cannot get characters individually; instead, take in a string and
  // store for later calls
  while ( stdin_buffer.empty() ) {
    std::getline( std::cin, stdin_buffer );
    stdin_buffer += '\n';
  }
  *data = stdin_buffer[0];
  stdin_buffer.erase( 0, 1 );
}

//------------------------------------------------------------------------
// write
//------------------------------------------------------------------------

#define TERMINAL_CHAR_ADDR 0xF0000000
#define TERMINAL_UNGETC_ADDR 0xF0000008

void FLTerminal::write( uint32_t addr, uint32_t data )
{
  // Unused address
  (void) addr;

  std::cout << (char) data;
  if ( (char) data == '\n' ) {
    std::cout.flush();
  }
}
