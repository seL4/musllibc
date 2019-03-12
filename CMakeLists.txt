#
# Copyright 2017, Data61
# Commonwealth Scientific and Industrial Research Organisation (CSIRO)
# ABN 41 687 119 230.
#
# This software may be distributed and modified according to the terms of
# the BSD 2-Clause license. Note that NO WARRANTY is provided.
# See "LICENSE_BSD2.txt" for details.
#
# @TAG(DATA61_BSD)
#

cmake_minimum_required(VERSION 3.5.1)

project(libmuslc NONE)

set(LIB_MUSLC_PARALLEL_BUILD true CACHE BOOL "Use `make -j` when building libmuslc")

# Construct the muslc version of our arch
if(Kernel64)
    if(${KernelArch} STREQUAL "arm")
        set(muslc_arch "aarch64")
    endif()
    if(${KernelArch} STREQUAL "x86")
        set(muslc_arch "x86_64")
    endif()
    if(${KernelArch} STREQUAL "riscv")
        set(muslc_arch "riscv")
    endif()
else()
    if(${KernelArch} STREQUAL "arm")
        set(muslc_arch "arm")
    endif()
    if(${KernelArch} STREQUAL "x86")
        set(muslc_arch "i386")
    endif()
    if(${KernelArch} STREQUAL "riscv")
        set(muslc_arch "riscv")
    endif()
endif()

set(LIB_MUSLC_GLOB_SOURCES OFF CACHE BOOL
    "This flag causes CMake to add lots of source files to its dependency lists
     which slows down its configuration times.
     When not making changes in the musllibc directory, it is likely not necessary
     to have this enabled.")
if(LIB_MUSLC_GLOB_SOURCES)
    file(GLOB_RECURSE deps **/*.c **/*.h **/*.S **/*.s)
endif()

set(parallel "")
if (LIB_MUSLC_PARALLEL_BUILD)
    set(parallel "-j")
endif()

# We make an attempt to extract compiler options from CMake
get_property(compile_options DIRECTORY PROPERTY COMPILE_OPTIONS)
separate_arguments(cmake_c_flags_sep NATIVE_COMMAND "${CMAKE_C_FLAGS}")
list(APPEND compile_options "${cmake_c_flags_sep}")
add_custom_command(
    OUTPUT
        build-temp/lib/libc.a
        "${CMAKE_BINARY_DIR}/lib/crt1.o"
        "${CMAKE_BINARY_DIR}/lib/crti.o"
        "${CMAKE_BINARY_DIR}/lib/crtn.o"
    # If we have to rebuild, first clear the temporary build directory as
    # we have no correctly captured the output files or dependencies
    COMMAND rm -r build-temp
    COMMAND mkdir -p build-temp
    COMMAND ${CMAKE_COMMAND} -E env
            TOOLPREFIX=${CROSS_COMPILER_PREFIX}
            # TODO: should also pass in the cflags for the CMAKE_BUILD_TYPE ?
            NK_CFLAGS="${compile_options}"
            TARGET=${muslc_arch}
        make -C build-temp ${parallel} -f "${CMAKE_CURRENT_SOURCE_DIR}/Makefile"
        "STAGE_DIR=${CMAKE_CURRENT_BINARY_DIR}/build-temp/stage"
        "SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}"
    COMMAND cp -a build-temp/lib/crt1.o "${CMAKE_BINARY_DIR}/lib/crt1.o"
    COMMAND cp -a build-temp/lib/crti.o "${CMAKE_BINARY_DIR}/lib/crti.o"
    COMMAND cp -a build-temp/lib/crtn.o "${CMAKE_BINARY_DIR}/lib/crtn.o"
    DEPENDS ${deps}
    COMMAND_EXPAND_LISTS
    COMMENT "Invoking muslc build system"
)

add_custom_target(muslc_gen
    DEPENDS
        build-temp/lib/libc.a
        "${CMAKE_BINARY_DIR}/lib/crt1.o"
        "${CMAKE_BINARY_DIR}/lib/crti.o"
)

add_library(muslc_imported STATIC IMPORTED GLOBAL)
add_dependencies(muslc_imported muslc_gen)
set_property(TARGET muslc_imported PROPERTY IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/build-temp/lib/libc.a")

add_library(muslc INTERFACE)
add_dependencies(muslc muslc_imported)
set_property(TARGET muslc PROPERTY INTERFACE_LINK_LIBRARIES muslc_imported)
target_include_directories(muslc INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/build-temp/stage/include")
