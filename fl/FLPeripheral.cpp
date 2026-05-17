//========================================================================
// FLPeripheral.cpp
//========================================================================
// Definitions of memory-mapped peripheral functions

#include "fl//FLPeripheral.h"

//------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------

bool can_read( const access_type_t access_type )
{
  return ( access_type == R ) | ( access_type == RW );
}
bool can_write( const access_type_t access_type )
{
  return ( access_type == W ) | ( access_type == RW );
}
bool addr_in_range( uint32_t addr, const address_range_t& address_range )
{
  return ( addr >= address_range.start_addr ) &&
         ( addr <= address_range.end_addr );
}

//------------------------------------------------------------------------
// try_read
//------------------------------------------------------------------------

bool FLPeripheral::try_read( uint32_t addr, uint32_t* data )
{
  for ( const address_range_t& address_range : get_address_ranges() ) {
    if ( addr_in_range( addr, address_range ) &&
         can_read( address_range.access_type ) ) {
      read( addr, data );
      return true;
    }
  }
  return false;
}

//------------------------------------------------------------------------
// try_write
//------------------------------------------------------------------------

bool FLPeripheral::try_write( uint32_t addr, uint32_t data )
{
  for ( const address_range_t& address_range : get_address_ranges() ) {
    if ( addr_in_range( addr, address_range ) &&
         can_write( address_range.access_type ) ) {
      write( addr, data );
      return true;
    }
  }
  return false;
}
