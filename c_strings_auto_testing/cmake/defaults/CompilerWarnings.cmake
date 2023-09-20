set(MSVC_WARNINGS /W4)
set(GCC_CLANG_WARNINGS -Wextra)

if (WARNINGS_AS_ERRORS)
    message("- [custom_cmake] Warnings as errors enabled. You can disable it in CMakeLists.txt")

    set(MSVC_WARNINGS ${MSVC_WARNINGS} /WX)
    set(GCC_CLANG_WARNINGS ${GCC_CLANG_WARNINGS} -Wall -pedantic -Werror -Wextra -Werror=vla -Wno-comment)
else ()
    set(GCC_CLANG_WARNINGS ${GCC_CLANG_WARNINGS} -Werror=vla)
endif ()

if (MSVC)
    add_compile_options(${MSVC_WARNINGS})
else ()
    add_compile_options(${GCC_CLANG_WARNINGS})
endif ()