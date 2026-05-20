# ========================================================================
# CMakeLists.txt
# ========================================================================
# Building RISCV binaries for use in Zeppelin

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/rv32.cmake)
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
add_compile_definitions(BUILTIN)

#-------------------------------------------------------------------------
# Set all of the directories to look in
#-------------------------------------------------------------------------

set(APP_SUBDIRS
  adventure
  echo
  hello
  sqrt
  ubmark
)

#-------------------------------------------------------------------------
# Set the libraries
#-------------------------------------------------------------------------

set(UTIL_FILES
  utils/zeppelin_exit.cpp
  utils/zeppelin_misc.cpp
  utils/zeppelin_rand.cpp
  utils/zeppelin_stats.cpp
  utils/zeppelin_stdio.cpp
  utils/zeppelin_string.cpp
  utils/zeppelin_wprintf.cpp
)

#-------------------------------------------------------------------------
# Object library for entry point
#-------------------------------------------------------------------------
# Need to do this with a custom command, so our linker script can later
# find it (otherwise CMake will put it somewhere crazy with a weird name)

# Need to replace spaces to avoid CMake escaping them
string(REPLACE " " ";" CMAKE_CXX_CUSTOM_FLAGS ${CMAKE_CXX_FLAGS})

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crt0.o
    COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_CUSTOM_FLAGS} -c ${CMAKE_CURRENT_SOURCE_DIR}/scripts/crt0.S -o ${CMAKE_CURRENT_BINARY_DIR}/crt0.o
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/scripts/crt0.S
)
add_custom_target(compile_crt ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/crt0.o)

#-------------------------------------------------------------------------
# Build the libraries
#-------------------------------------------------------------------------

add_library(UTILS STATIC ${UTIL_FILES})

#-------------------------------------------------------------------------
# Make targets
#-------------------------------------------------------------------------

set(PROGS "")

foreach(APP_SUBDIR ${APP_SUBDIRS})
  add_subdirectory(${APP_SUBDIR} "${CMAKE_CURRENT_BINARY_DIR}/${APP_SUBDIR}_cmake")
  add_prefix(SRC_FILES "${APP_SUBDIR}/")
  add_prefix(APP_FILES "${APP_SUBDIR}/")

  set(ABSOLUTE_SRC_FILES ${SRC_FILES})
  add_prefix(ABSOLUTE_SRC_FILES "${CMAKE_CURRENT_SOURCE_DIR}/")
  
  foreach(APP_FILE_REL_PATH ${APP_FILES})
    set(APP_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${APP_FILE_REL_PATH}")
    get_leaf(APP_FILE ${APP_FILE_PATH})
    remove_extension(APP_BIN ${APP_FILE})
  
    add_executable(
      app-${APP_BIN} 
      ${APP_FILE_PATH}
      ${ABSOLUTE_SRC_FILES}
    )
    target_compile_options(app-${APP_BIN} PRIVATE -Wall -Wextra -Wpedantic)
    add_dependencies(app-${APP_BIN} compile_crt)
    set_target_properties(app-${APP_BIN} PROPERTIES OUTPUT_NAME ${APP_BIN})
    target_compile_options(app-${APP_BIN} PRIVATE -O3 -Wall -Wextra -Wpedantic)
    target_link_libraries(app-${APP_BIN} PRIVATE UTILS)

    # Add to list of programs for parent
    set(app-${APP_BIN}-files
      ${APP_FILE_REL_PATH}
      ${SRC_FILES}
    PARENT_SCOPE)
    set(PROGS ${PROGS} ${APP_BIN})
  endforeach(APP_FILE_REL_PATH)
endforeach(APP_SUBDIR)

#-------------------------------------------------------------------------
# Give parent our programs for native builds
#-------------------------------------------------------------------------

set(PROGS ${PROGS} PARENT_SCOPE)