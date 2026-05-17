//========================================================================
// FLTerminal.h
//========================================================================
// A memory-mapped peripheral for getting user input

#ifndef FL_TERMINAL_H
#define FL_TERMINAL_H

#include "fl/FLPeripheral.h"

class FLTerminal : public FLPeripheral {
  //----------------------------------------------------------------------
  // Address Ranges
  //----------------------------------------------------------------------

  std::vector<address_range_t> address_ranges = {
      { 0xF0000000, 0xF0000000, W },  // stdout
      { 0xF0000004, 0xF0000004, R },  // stdin
  };

  //----------------------------------------------------------------------
  // Accessors
  //----------------------------------------------------------------------

  void read( uint32_t addr, uint32_t* data ) override;
  void write( uint32_t addr, uint32_t data ) override;
  const std::vector<address_range_t>& get_address_ranges() override
  {
    return address_ranges;
  }
};

#endif  // FL_TERMINAL_H
