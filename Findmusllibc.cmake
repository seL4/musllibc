#
# Copyright 2019, Data61
# Commonwealth Scientific and Industrial Research Organisation (CSIRO)
# ABN 41 687 119 230.
#
# This software may be distributed and modified according to the terms of
# the BSD 2-Clause license. Note that NO WARRANTY is provided.
# See "LICENSE_BSD2.txt" for details.
#
# @TAG(DATA61_BSD)
#

set(MUSLLIBC_CURRENT_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE STRING "")
mark_as_advanced(MUSLLIBC_CURRENT_DIR)

macro(musllibc_set_environment_flags)
    include(environment_flags)
    add_default_compilation_options()

    find_libgcc_files()

    set(CRTObjFiles "${CMAKE_BINARY_DIR}/lib/crt0.o ${CMAKE_BINARY_DIR}/lib/crti.o ${CRTBeginFile}")
    set(FinObjFiles "${CRTEndFile} ${CMAKE_BINARY_DIR}/lib/crtn.o")

    # libgcc has dependencies implemented by libc and so we use link groups to resolve these.
    # This seems to be the same behaviour gcc has when building static binaries.
    set(common_link_string "<LINK_FLAGS> ${CRTObjFiles} <OBJECTS> -Wl,--start-group \
        ${libgcc} <LINK_LIBRARIES> -Wl,--end-group ${FinObjFiles} -o <TARGET>")
    set(
        CMAKE_C_LINK_EXECUTABLE
        "<CMAKE_C_COMPILER>  <FLAGS> <CMAKE_C_LINK_FLAGS> ${common_link_string}"
    )
    set(
        CMAKE_CXX_LINK_EXECUTABLE
        "<CMAKE_CXX_COMPILER>  <FLAGS> <CMAKE_CXX_LINK_FLAGS> ${common_link_string}"
    )
    set(
        CMAKE_ASM_LINK_EXECUTABLE
        "<CMAKE_ASM_COMPILER>  <FLAGS> <CMAKE_ASM_LINK_FLAGS> ${common_link_string}"
    )

    # We want to check what we can set the -mfloat-abi to on arm and if that matches what is requested
    add_fpu_compilation_options()
    # Now all platform compilation flags have been set, we can check the compiler against flags
    include(check_arch_compiler)
    check_arch_compiler()

endmacro()

macro(musllibc_import_library)
    add_subdirectory(${MUSLLIBC_CURRENT_DIR} musllibc)
endmacro()

macro(musllibc_setup_build_environment_with_sel4runtime)
    find_package(sel4runtime REQUIRED)
    musllibc_set_environment_flags()
    sel4runtime_import_project()
    musllibc_import_library()
endmacro()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(musllibc DEFAULT_MSG MUSLLIBC_CURRENT_DIR)
