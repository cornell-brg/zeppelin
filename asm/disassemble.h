//========================================================================
// disassemble.h
//========================================================================
// Declarations of our disassembly functions

#ifndef DISASSEMBLE_H
#define DISASSEMBLE_H

#include <cstdint>

extern "C" const char* disassemble( const uint32_t* vbinary,
                                    const uint32_t* pc );

#endif  // DISASSEMBLE_H