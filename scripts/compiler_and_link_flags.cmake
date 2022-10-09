include_guard()

include(${CURRENT_BASE_PATH}/scripts/process_dot_config.cmake)

add_library(ProjectCommonFlags INTERFACE)

set_property(TARGET ProjectCommonFlags
  PROPERTY POSITION_INDEPENDENT_CODE YES
)

target_compile_options(ProjectCommonFlags INTERFACE "-g")
target_compile_options(ProjectCommonFlags INTERFACE "-fPIC")
target_compile_options(ProjectCommonFlags INTERFACE "-O0")
target_compile_options(ProjectCommonFlags INTERFACE "-Wall")
target_compile_options(ProjectCommonFlags INTERFACE "-fno-common")
target_compile_options(ProjectCommonFlags INTERFACE "-fno-omit-frame-pointer")
target_compile_options(ProjectCommonFlags INTERFACE "-mno-omit-leaf-frame-pointer")
target_compile_options(ProjectCommonFlags INTERFACE "-fno-optimize-sibling-calls")
target_link_options(ProjectCommonFlags INTERFACE "-fPIC")

if (DEFINED BUILD_IS_KERNEL)
  target_compile_options(ProjectCommonFlags INTERFACE "-ffreestanding")
  target_compile_options(ProjectCommonFlags INTERFACE "-nostdinc")
  target_compile_options(ProjectCommonFlags INTERFACE "-nostdlib")
  target_link_options(ProjectCommonFlags INTERFACE "-ffreestanding")
  target_link_options(ProjectCommonFlags INTERFACE "-nostdinc")
  target_link_options(ProjectCommonFlags INTERFACE "-nostdlib")
else()
  target_compile_options(ProjectCommonFlags INTERFACE "-fblocks")
  target_compile_options(ProjectCommonFlags INTERFACE "-fvisibility=hidden")
endif()

if (DEFINED BUILD_CFLAGS)
  separate_arguments(tmp UNIX_COMMAND ${BUILD_CFLAGS})
  target_compile_options(ProjectCommonFlags INTERFACE ${tmp})
endif()

if (DEFINED BUILD_LDFLAGS)
  separate_arguments(tmp UNIX_COMMAND ${BUILD_LDFLAGS})
  target_compile_options(ProjectCommonFlags INTERFACE ${tmp})
endif()

if (DEFINED BUILD_IS_KERNEL)
  if (DEFINED CONFIG_UBSAN OR 
      DEFINED CONFIG_ASAN OR 
      DEFINED CONFIG_TSAN OR 
      DEFINED CONFIG_MSAN OR
      DEFINED CONFIG_LLVM_XRAY)
    message(FATAL "Not available in kernel compilation")
  endif()
endif()

if (DEFINED CONFIG_UBSAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=undefined")
  #target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize-address-use-after-return=always")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=float-divide-by-zero")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=implicit-conversion")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=unsigned-integer-overflow")

  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=undefined")
  target_link_options(ProjectCommonFlags INTERFACE "-static-libsan")
endif()

target_compile_definitions(ProjectCommonFlags INTERFACE "PROCESSED_BY_CMAKE")

if (DEFINED CONFIG_ASAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize-address-use-after-scope")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=address")
  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=address")
endif()

if (DEFINED CONFIG_TSAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=thread")
  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=thread")
endif()

if (DEFINED CONFIG_LLVM_XRAY)
  target_compile_options(ProjectCommonFlags INTERFACE "-fxray-instrument")
  target_compile_options(ProjectCommonFlags INTERFACE "-fxray-instruction-threshold=1")
  target_link_options(ProjectCommonFlags INTERFACE "-fxray-instrument")
  target_link_options(ProjectCommonFlags INTERFACE "-fxray-instruction-threshold=1")
endif()

if (DEFINED CONFIG_MSAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize-memory-track-origins")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=memory")
  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=memory")
endif()

if (NOT DEFINED BUILD_IS_KERNEL)
  target_link_libraries(ProjectCommonFlags INTERFACE BlocksRuntime)
  target_link_libraries(ProjectCommonFlags INTERFACE pthread)
endif()

target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_BINARY_DIR}")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_BINARY_DIR}/src")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_SOURCE_DIR}/src")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_SOURCE_DIR}/src/collection")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_SOURCE_DIR}/include")
target_include_directories(ProjectCommonFlags INTERFACE ${BUILD_INCLUDE_DIRS})

