# Copyright (c) Facebook, Inc. and its affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

option(INCLUDE_FB_INTEGRATION_LIB "If enabled, include dependencies on \
  Facebook specific directories"
  OFF)

file(GLOB INTEGRATION_SRCS "*.py")

# Linux-specific integration tests.
if(WIN32 OR APPLE)
  list(
    REMOVE_ITEM INTEGRATION_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/linux_cgroup_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/stale_test.py
  )
endif()
if(WIN32)
  list(
    REMOVE_ITEM INTEGRATION_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/chown_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/mmap_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/takeover_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/userinfo_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/stale_inode_test.py
  )
endif()

# The following integration test files contain one or more tests that require
# pexpect.  For now we disable the entire files when pexpect is unavailable.
if(NOT pexpect_FOUND)
  list(
    REMOVE_ITEM INTEGRATION_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/health_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/restart_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/service_log_test.py
    ${CMAKE_CURRENT_SOURCE_DIR}/stop_test.py
  )
endif()

add_fb_python_unittest(
  integration_tests
  SOURCES ${INTEGRATION_SRCS}
  WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  DEPENDS
    edenfsctl.real.main_lib
    eden_integration_lib
    eden_hg_integration_lib
  ENV
    "CMAKE_SOURCE_DIR=${CMAKE_SOURCE_DIR}"
)

add_subdirectory(hg)
add_subdirectory(helpers)

if(INCLUDE_FB_INTEGRATION_LIB)
  add_subdirectory(facebook/lib)
endif()

add_subdirectory(lib)
