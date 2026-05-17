//========================================================================
// FLRegfile.h
//========================================================================
// Declarations for our functional-level register file

#ifndef FL_REGFILE_H
#define FL_REGFILE_H

#include <cstdint>

class FLRegfile {
  //----------------------------------------------------------------------
  // Public accessor functions
  //----------------------------------------------------------------------
 public:
  // Accessor
  uint32_t& operator[]( uint32_t idx );

  //----------------------------------------------------------------------
  // Protected attrributes
  //----------------------------------------------------------------------
 protected:
  uint32_t regs[32];
};

#endif  // FL_REGFILE_H