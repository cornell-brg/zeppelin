//========================================================================
// FLMem.cpp
//========================================================================
// Definitions of our functional-level memory utilities

#include "asm/assemble.h"
#include "fl/FLMem.h"
#include <format>
#include <stdexcept>

//------------------------------------------------------------------------
// FLMem::init
//------------------------------------------------------------------------

void FLMem::init( uint32_t addr, uint32_t data )
{
  mem[addr] = data;
}

void FLMem::init( uint32_t addr, std::string assembly )
{
  mem[addr] = assemble( assembly.c_str(), &addr );
}

//------------------------------------------------------------------------
// FLMem::clear
//------------------------------------------------------------------------

void FLMem::clear()
{
  mem.clear();
}

//------------------------------------------------------------------------
// FLMem::add_peripheral
//------------------------------------------------------------------------

void FLMem::add_peripheral( FLPeripheral* peripheral )
{
  peripherals.push_back( peripheral );
}

//------------------------------------------------------------------------
// Loading
//------------------------------------------------------------------------

uint8_t FLMem::loadb( uint32_t addr )
{
  uint32_t peripheral_data;
  for ( FLPeripheral* peripheral : peripherals ) {
    if ( peripheral->try_read( addr, &peripheral_data ) ) {
      std::string excp = std::format(
          "Sub-word load from peripherals are unsupported: '0x{:x}'",
          addr );
      throw std::invalid_argument( excp );
    }
  }

  // Otherwise, get from memory
  uint32_t aligned_addr = addr & 0xFFFFFFFC;
  int      offset       = addr & 0x00000003;

  return ( mem[aligned_addr] >> ( 8 * offset ) ) &
         0x000000FF;  // 0 if not already mapped
}

uint16_t FLMem::loadh( uint32_t addr )
{
  uint32_t peripheral_data;
  for ( FLPeripheral* peripheral : peripherals ) {
    if ( peripheral->try_read( addr, &peripheral_data ) ) {
      std::string excp = std::format(
          "Sub-word load from peripherals are unsupported: '0x{:x}'",
          addr );
      throw std::invalid_argument( excp );
    }
  }

  // Otherwise, get from memory
  uint32_t aligned_addr = addr & 0xFFFFFFFC;
  int      offset       = addr & 0x00000003;

  return ( mem[aligned_addr] >> ( 8 * offset ) ) &
         0x0000FFFF;  // 0 if not already mapped
}

uint32_t FLMem::loadw( uint32_t addr )
{
  uint32_t peripheral_data;
  for ( FLPeripheral* peripheral : peripherals ) {
    if ( peripheral->try_read( addr, &peripheral_data ) ) {
      return peripheral_data;
    }
  }

  // Otherwise, get from memory
  return mem[addr];  // 0 if not already mapped
}

//------------------------------------------------------------------------
// Storing
//------------------------------------------------------------------------

void FLMem::storeb( uint32_t addr, uint8_t data )
{
  for ( FLPeripheral* peripheral : peripherals ) {
    if ( peripheral->try_write( addr, data ) ) {
      std::string excp = std::format(
          "Sub-word store to peripherals are unsupported: '0x{:x}'",
          addr );
      throw std::invalid_argument( excp );
    }
  }

  // Otherwise, store to memory
  uint32_t aligned_addr = addr & 0xFFFFFFFC;
  int      offset       = addr & 0x00000003;
  uint32_t data_mask    = ~( 0xFF << ( 8 * offset ) );
  uint32_t new_data     = data << ( 8 * offset );

  uint32_t curr_data = mem[aligned_addr];
  mem[aligned_addr]  = ( curr_data & data_mask ) | new_data;
}

void FLMem::storeh( uint32_t addr, uint16_t data )
{
  for ( FLPeripheral* peripheral : peripherals ) {
    if ( peripheral->try_write( addr, data ) ) {
      std::string excp = std::format(
          "Sub-word store to peripherals are unsupported: '0x{:x}'",
          addr );
      throw std::invalid_argument( excp );
    }
  }

  // Otherwise, store to memory
  uint32_t aligned_addr = addr & 0xFFFFFFFC;
  int      offset       = addr & 0x00000003;
  uint32_t data_mask    = ~( 0xFFFF << ( 8 * offset ) );
  uint32_t new_data     = data << ( 8 * offset );

  uint32_t curr_data = mem[aligned_addr];
  mem[aligned_addr]  = ( curr_data & data_mask ) | new_data;
}

void FLMem::storew( uint32_t addr, uint32_t data )
{
  for ( FLPeripheral* peripheral : peripherals ) {
    if ( peripheral->try_write( addr, data ) ) {
      return;
    }
  }

  // Otherwise, store to memory
  mem[addr] = data;
}

//------------------------------------------------------------------------
// FLMem::operator[]
//------------------------------------------------------------------------
// Doesn't check peripherals

// Store - return uint32_t&
uint32_t& FLMem::operator[]( uint32_t addr )
{
  return mem[addr];
}