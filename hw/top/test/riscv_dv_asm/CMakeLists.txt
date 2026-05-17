# ========================================================================
# CMakeLists.txt
# ========================================================================
# Building RISCV assembly test binaries for Zeppelin ELF testing

# Bring in the RV32 cross-compiler and base flags. rv32.cmake appends
# -T.../scripts/zeppelin.ld to CMAKE_EXE_LINKER_FLAGS using its own
# CMAKE_CURRENT_SOURCE_DIR, which resolves to riscv_dv_asm/ here. We
# override the linker script immediately after to use zeppelin_test.ld
# instead, keeping this build fully independent of app/.
include(${CMAKE_CURRENT_SOURCE_DIR}/../../../../app/cmake/rv32.cmake)

string(REGEX REPLACE
  "-T[^ ]*zeppelin\\.ld"
  "-T${CMAKE_CURRENT_SOURCE_DIR}/scripts/zeppelin_test.ld"
  CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}"
)

#-------------------------------------------------------------------------
# Entry point
#-------------------------------------------------------------------------
# crt0_test.o must match the name in STARTUP() in zeppelin_test.ld.
# CMAKE_ASM_FLAGS carries the correct -march/-mabi flags from rv32.cmake.

string(REPLACE " " ";" CMAKE_ASM_CUSTOM_FLAGS "${CMAKE_ASM_FLAGS}")

add_custom_command(
  OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/crt0_test.o
  COMMAND ${CMAKE_ASM_COMPILER} ${CMAKE_ASM_CUSTOM_FLAGS}
          -c ${CMAKE_CURRENT_SOURCE_DIR}/scripts/crt0_test.S
          -o ${CMAKE_CURRENT_BINARY_DIR}/crt0_test.o
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/scripts/crt0_test.S
)
add_custom_target(compile_crt_test ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/crt0_test.o
)

#-------------------------------------------------------------------------
# Assembly test targets
#-------------------------------------------------------------------------
# CONFIGURE_DEPENDS re-runs CMake when .S files are added or removed from
# test_asm/, so freshly generated tests are picked up automatically.

set(ASM_TEST_PROGS "")
set(ASM_TEST_TARGETS "")

file(GLOB ASM_TEST_FILES CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/test_asm/*.S"
)

foreach(ASM_FILE_PATH ${ASM_TEST_FILES})
  get_filename_component(ASM_BIN ${ASM_FILE_PATH} NAME_WE)

  add_executable(asm-test-${ASM_BIN} ${ASM_FILE_PATH})
  add_dependencies(asm-test-${ASM_BIN} compile_crt_test)
  set_target_properties(asm-test-${ASM_BIN} PROPERTIES
    OUTPUT_NAME              ${ASM_BIN}
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/riscv_dv_asm"
  )

  set(ASM_TEST_PROGS   ${ASM_TEST_PROGS}   ${ASM_BIN})
  set(ASM_TEST_TARGETS ${ASM_TEST_TARGETS} asm-test-${ASM_BIN})
endforeach()

add_custom_target(asm-tests DEPENDS ${ASM_TEST_TARGETS})

# Propagate program names to the root CMakeLists so it can register
# elf_tests.cmake entries for each generated test.
set(ASM_TEST_PROGS ${ASM_TEST_PROGS} PARENT_SCOPE)
