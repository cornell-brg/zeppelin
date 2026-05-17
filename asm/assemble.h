//========================================================================
// assemble.h
//========================================================================
// Declarations of our assembly functions

#ifndef ASSEMBLE_H
#define ASSEMBLE_H

#include <cstdint>

extern "C" uint32_t assemble( const char* vassembly, uint32_t* vpc );

#endif  // ASSEMBLE_H