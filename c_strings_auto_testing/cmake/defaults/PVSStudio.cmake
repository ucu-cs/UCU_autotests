if (ENABLE_PVS_STUDIO)
    message("- PVS Studio enabled. You can disable it in CMakeLists.txt")
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
    include(cmake/extra/PVS-Studio.cmake)
    foreach(TARGET IN LISTS ${ALL_TARGETS})
        pvs_studio_add_target(TARGET ${TARGET}.analyze ALL
                OUTPUT FORMAT errorfile
                ANALYZE ${TARGET}
                LOG target.err)
    endforeach()

else ()
    message(NOTICE "\nConsider using PVS-Studio with `-DENABLE_PVS_STUDIO=ON` flag or Windows GUI application.\n")
endif ()
