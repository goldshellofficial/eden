# Copyright (c) Facebook, Inc. and its affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

file(GLOB INTEGRATION_LIB_SRCS "*.py")
if(pexpect_FOUND)
  list(APPEND INTEGRATION_LIB_DEPENDENCIES pexpect::pexpect)
else()
  list(REMOVE_ITEM INTEGRATION_LIB_SRCS pexpect.py)
endif()

if(INCLUDE_FB_INTEGRATION_LIB)
  list(APPEND INTEGRATION_LIB_DEPENDENCIES eden_integration_fb_lib)
endif()

add_fb_python_library(
  eden_integration_lib
  SOURCES ${INTEGRATION_LIB_SRCS}
  DEPENDS
    edenfsctl.real.main_lib
    eden_py
    eden_service_thrift_py
    eden_test_support
    ${INTEGRATION_LIB_DEPENDENCIES}
)
