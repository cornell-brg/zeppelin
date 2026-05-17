//========================================================================
// parse_elf.h
//========================================================================
// Declarations for ELF parsing utilities

#ifndef PARSE_ELF_H
#define PARSE_ELF_H

#include <cstdint>
#include <functional>
#include <string>

// -----------------------------------------------------------------------
// parse_elf
// -----------------------------------------------------------------------
// The main ELF parsing utility. To be widely applicable, it uses a
// function of the signature
//
// set_mem( uint32_t addr, uint32_t data )
//
// which should set the application's memory at address `addr` to `data`

void parse_elf( std::string                               elf_path,
                std::function<void( uint32_t, uint32_t )> set_mem );

#endif  // PARSE_ELF_H