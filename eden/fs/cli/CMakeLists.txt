# Copyright (c) Facebook, Inc. and its affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

file(GLOB EDENFSCTL_SRCS "*.py" "doctor/*.py")
add_fb_python_executable(
  edenfsctl.real
  MAIN_MODULE eden.fs.cli.main:zipapp_main
  SOURCES ${EDENFSCTL_SRCS}
  DEPENDS
    eden_py
    eden_overlay_thrift_py
    eden_service_thrift_py
    FBThrift::thrift_py_inspect
    python-toml::python-toml
    python-filelock::python-filelock
)
install_fb_python_executable(edenfsctl.real)
