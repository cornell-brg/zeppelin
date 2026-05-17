//========================================================================
// FLTrace.cpp
//========================================================================
// Definitions for our processor trace

#include "fl/FLTrace.h"
#include <format>
#include <string>

//------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------

FLTrace::FLTrace( uint32_t pc, uint32_t waddr, uint32_t wdata, bool wen )
    : pc( pc ), waddr( waddr ), wdata( wdata ), wen( wen ) {};

// Assume a struct of the following format:
//
// typedef struct packed {
//   bit        wen;
//   bit  [4:0] waddr;
//   bit [31:0] wdata;
//   bit [31:0] pc;
// } inst_trace;
//
// Pack the bits accordingly (pc is least-significant word)
FLTrace::FLTrace( uint32_t *vstruct )
{
  pc    = vstruct[0];
  wdata = vstruct[1];
  waddr = vstruct[2] & 0x0000001F;
  wen   = ( vstruct[2] >> 5 ) & 0x00000001;
}

//------------------------------------------------------------------------
// Equality
//------------------------------------------------------------------------

bool FLTrace::operator==( const FLTrace &other )
{
  return ( pc == other.pc ) && ( waddr == other.waddr ) &&
         ( wdata == other.wdata ) && ( wen == other.wen );
}

bool FLTrace::operator!=( const FLTrace &other )
{
  return !( *this == other );
}

//------------------------------------------------------------------------
// String representation
//------------------------------------------------------------------------

std::string FLTrace::str() const
{
  std::string str_rep = std::format( "0x{:08x}: ", pc );
  if ( wen ) {
    str_rep += std::format( "0x{:08x} -> R[{}]", wdata, waddr );
  }
  return str_rep;
}

std::ostream &operator<<( std::ostream &out, const FLTrace &trace )
{
  out << trace.str();
  return out;
}

//------------------------------------------------------------------------
// Verilog Representation
//------------------------------------------------------------------------
// Assume a struct of the following format:
//
// typedef struct packed {
//   bit        wen;
//   bit  [4:0] waddr;
//   bit [31:0] wdata;
//   bit [31:0] pc;
// } inst_trace;
//
// Pack the bits accordingly (pc is least-significant word)

void FLTrace::vrep( uint32_t *vstruct )
{
  vstruct[0] = pc;
  vstruct[1] = wdata;
  vstruct[2] = waddr | ( (uint32_t) ( wen ) << 5 );
}
