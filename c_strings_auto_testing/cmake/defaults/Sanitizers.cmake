if (ENABLE_SANITIZERS)
    message("- Sanitizers enabled. You can disable it in CMakeLists.txt")
    if (CMAKE_C_COMPILER_ID STREQUAL "MSVC" OR CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        message(WARNING "Sanitizers for the MSVC are not yet supported")
    elseif (MINGW) #  OR CYGWIN?
        message(WARNING "Sanitizers for the MINGW are not yet supported")
    else ()
        if (ENABLE_UBSan)
            set(SANITIZE_UNDEFINED ON)
        endif ()

        # Only one of Memory, Address, or Thread sanitizers is applicable at the time
        if (CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
            if (ENABLE_MSAN)
                message("- MSAN Enabled. You can disable it in CMakeLists.txt")
                set(SANITIZE_MEMORY ON)
            elseif (ENABLE_ASAN)
                message("- ASAN Enabled. You can disable it in CMakeLists.txt")
                set(SANITIZE_ADDRESS ON)
            elseif (ENABLE_TSan)
                message("- TSAN Enabled. You can disable it in CMakeLists.txt")
                set(SANITIZE_THREAD ON)
            endif ()
        elseif (CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            if (ENABLE_MSAN)
                message(WARNING "GCC does not have a SANITIZE_MEMORY.")
            elseif (ENABLE_ASAN)
                message("- ASAN Enabled. You can disable it in CMakeLists.txt")
                set(SANITIZE_ADDRESS ON)
            elseif(ENABLE_TSan)
                message("- TSAN Enabled. You can disable it in CMakeLists.txt")
                set(SANITIZE_THREAD ON)
            endif ()
        endif ()

        set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/extra/sanitizers" ${CMAKE_MODULE_PATH})
        find_package(Sanitizers)

        add_sanitizers(${ALL_TARGETS})
    endif ()

endif () # For MSVC

