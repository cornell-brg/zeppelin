//========================================================================
// FLMem.h
//========================================================================
// Declarations of our functional-level memory utilities

#ifndef FL_MEM_H
#define FL_MEM_H

#include "fl/FLPeripheral.h"
#include <cstdint>
#include <map>
#include <string>
#include <vector>

class FLMem {
  //----------------------------------------------------------------------
  // Public accessor functions
  //----------------------------------------------------------------------
 public:
  // Initialize memory
  void init( uint32_t addr, uint32_t inst );
  void init( uint32_t addr, std::string assembly );

  // Clear memory
  void clear();

  // Add peripherals
  void add_peripheral( FLPeripheral* peripheral );

  // Access memory
  uint8_t  loadb( uint32_t addr );
  uint16_t loadh( uint32_t addr );
  uint32_t loadw( uint32_t addr );
  void     storeb( uint32_t addr, uint8_t data );
  void     storeh( uint32_t addr, uint16_t data );
  void     storew( uint32_t addr, uint32_t data );

  // Overload with bracket for easier syntax - directly modify map,
  // doesn't check peripherals
  uint32_t& operator[]( uint32_t addr );

  //----------------------------------------------------------------------
  // Protected attrributes
  //----------------------------------------------------------------------
 protected:
  std::map<uint32_t, uint32_t> mem;
  std::vector<FLPeripheral*>   peripherals;
};

#endif  // FL_MEM_H