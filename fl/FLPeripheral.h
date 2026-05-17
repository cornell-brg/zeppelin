//========================================================================
// FLPeripheral.h
//========================================================================
// Declarations for a memory-mapped peripheral

#ifndef FL_PERIPHERAL_H
#define FL_PERIPHERAL_H

#include <cstdint>
#include <vector>

//------------------------------------------------------------------------
// Helper type definitions
//------------------------------------------------------------------------

enum access_type_t { R, W, RW };

// Addresses are inclusive
typedef struct {
  uint32_t      start_addr;
  uint32_t      end_addr;
  access_type_t access_type;
} address_range_t;

//------------------------------------------------------------------------
// FLPeripheral
//------------------------------------------------------------------------

class FLPeripheral {
  //----------------------------------------------------------------------
  // Public accessor functions
  //----------------------------------------------------------------------
 public:
  // Return whether a read or write corresponds to the peripheral, and
  // performs if so
  bool try_read( uint32_t addr, uint32_t* data );
  bool try_write( uint32_t addr, uint32_t data );

  //----------------------------------------------------------------------
  // Protected attributes and functions
  //----------------------------------------------------------------------
  // Children should overload get_address_ranges to specify the virtual
  // memory-mapped space, as well as read/write to operate on that
  // space

 protected:
  virtual void read( uint32_t addr, uint32_t* data )               = 0;
  virtual void write( uint32_t addr, uint32_t data )               = 0;
  virtual const std::vector<address_range_t>& get_address_ranges() = 0;
};

#endif  // FL_PERIPHERAL_H