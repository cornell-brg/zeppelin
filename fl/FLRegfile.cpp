//========================================================================
// FLRegfile.cpp
//========================================================================
// Definitions for our functional-level register file

#include "fl/FLRegfile.h"

//------------------------------------------------------------------------
// Accessors
//------------------------------------------------------------------------

// Write
uint32_t& FLRegfile::operator[]( uint32_t idx )
{
  // Always reset x0, so it's always read as 0
  regs[0] = 0;
  return regs[idx];
}