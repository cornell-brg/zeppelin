//========================================================================
// zeppelin_exit.cpp
//========================================================================
// A mechanism for Zeppelin to signal to exit

#include "utils/zeppelin_exit.h"

#ifdef _RISCV

void zeppelin_exit( int exit_code )
{
  int* exit_code_peripheral = (int*) 0xFFFFFFFC;
  *exit_code_peripheral     = exit_code;
}

#endif  // _RISCV