include_guard()

include(${CURRENT_BASE_PATH}/scripts/process_dot_config.cmake)

add_library(ProjectCommonFlags INTERFACE)

target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_BINARY_DIR}")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_BINARY_DIR}/src")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_SOURCE_DIR}/src")
target_include_directories(ProjectCommonFlags INTERFACE "${PROJECT_SOURCE_DIR}/include")
target_include_directories(ProjectCommonFlags INTERFACE ${BUILD_INCLUDE_DIRS})

target_compile_options(ProjectCommonFlags INTERFACE "-x assembler-with-cpp")

if (DEFINED BUILD_OVERRIDE_PROJECT_FLAGS)
  separate_arguments(tmp UNIX_COMMAND ${CONFIG_BUILD_OVERRIDE_LDFLAGS})
  target_link_options(ProjectCommonFlags INTERFACE ${tmp})
  
  separate_arguments(tmp UNIX_COMMAND ${CONFIG_BUILD_OVERRIDE_CFLAGS})
  target_compile_options(ProjectCommonFlags INTERFACE ${tmp})
else()
  # Default options
  # Kernel don't have luxury of dynamic linker UwU
  if (DEFINED CONFIG_BUILD_IS_KERNEL)
    target_compile_options(ProjectCommonFlags INTERFACE "-static")
    target_link_options(ProjectCommonFlags INTERFACE "-static")
  endif()
  
  if (DEFINED CONFIG_BUILD_CAN_RELOCATE)
    target_compile_options(ProjectCommonFlags INTERFACE "-fpic")
    target_link_options(ProjectCommonFlags INTERFACE "-fpic")
  else()
    target_compile_options(ProjectCommonFlags INTERFACE "-fno-pic")
    target_link_options(ProjectCommonFlags INTERFACE "-fno-pic")
  endif()
  
  target_compile_options(ProjectCommonFlags INTERFACE "-fno-common")
  target_compile_options(ProjectCommonFlags INTERFACE "-Wall")
  target_compile_options(ProjectCommonFlags INTERFACE "-fvisibility=hidden")
  target_compile_options(ProjectCommonFlags INTERFACE "-fmacro-prefix-map=${CMAKE_SOURCE_DIR}=.")
endif()

# Append from build.cmake
if (DEFINED BUILD_LDFLAGS)
  separate_arguments(tmp UNIX_COMMAND ${BUILD_LDFLAGS})
  target_link_options(ProjectCommonFlags INTERFACE ${tmp})
endif()

if (DEFINED BUILD_CFLAGS)
  separate_arguments(tmp UNIX_COMMAND ${BUILD_CFLAGS})
  target_compile_options(ProjectCommonFlags INTERFACE ${tmp})
endif()

# Append from kconfig
if (DEFINED CONFIG_BUILD_LDFLAGS)
  separate_arguments(tmp UNIX_COMMAND ${CONFIG_BUILD_LDFLAGS})
  target_link_options(ProjectCommonFlags INTERFACE ${tmp})
endif()

if (DEFINED CONFIG_BUILD_CFLAGS)
  separate_arguments(tmp UNIX_COMMAND ${CONFIG_BUILD_CFLAGS})
  target_compile_options(ProjectCommonFlags INTERFACE ${tmp})
endif()

if (DEFINED CONFIG_BUILD_USERSPACE)
  target_compile_options(ProjectCommonFlags INTERFACE "-D_POSIX_C_SOURCE=200809L")
  target_link_libraries(ProjectCommonFlags INTERFACE pthread)
endif()

if (DEFINED CONFIG_BUILD_HAVE_CLANG_BLOCKS_SUPPORT)
  target_compile_options(ProjectCommonFlags INTERFACE "-fblocks")
  if (DEFINED CONFIG_BUILD_USERSPACE)
    target_link_libraries(ProjectCommonFlags INTERFACE BlocksRuntime)
  endif()
endif()

if (DEFINED CONFIG_BUILD_GENERATE_DEBUG_INFO)
  target_compile_options(ProjectCommonFlags INTERFACE "-g")
endif()

if (DEFINED CONFIG_BUILD_LTO_THIN)
  target_compile_options(ProjectCommonFlags INTERFACE "-flto=thin")
  target_link_options(ProjectCommonFlags INTERFACE "-flto=thin")
endif()

if (DEFINED CONFIG_BUILD_LTO_FULL)
  target_compile_options(ProjectCommonFlags INTERFACE "-flto=full")
  target_link_options(ProjectCommonFlags INTERFACE "-flto=full")
endif()

if(DEFINED CONFIG_BUILD_MAXIMUM_PERFORMANCE)
  target_compile_options(ProjectCommonFlags INTERFACE "-O3")
  target_compile_options(ProjectCommonFlags INTERFACE "-fomit-frame-pointer")
  target_compile_options(ProjectCommonFlags INTERFACE "-momit-leaf-frame-pointer")
  target_compile_options(ProjectCommonFlags INTERFACE "-foptimize-sibling-calls")
endif()

if (NOT DEFINED CONFIG_BUILD_OVERRIDE_PROJECT_FLAGS)
  target_compile_options(ProjectCommonFlags INTERFACE "-O0") 
  target_compile_options(ProjectCommonFlags INTERFACE "-fno-omit-frame-pointer")
  target_compile_options(ProjectCommonFlags INTERFACE "-mno-omit-leaf-frame-pointer")
  target_compile_options(ProjectCommonFlags INTERFACE "-fno-optimize-sibling-calls")
endif()

if (DEFINED CONFIG_BUILD_IS_KERNEL)
  target_compile_options(ProjectCommonFlags INTERFACE "-ffreestanding")
  target_compile_options(ProjectCommonFlags INTERFACE "-nostdinc")
  target_compile_options(ProjectCommonFlags INTERFACE "-nostdlib")
  target_link_options(ProjectCommonFlags INTERFACE "-ffreestanding")
  target_link_options(ProjectCommonFlags INTERFACE "-nostdinc")
  target_link_options(ProjectCommonFlags INTERFACE "-nostdlib")
endif()

if (DEFINED CONFIG_BUILD_UBSAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=undefined")
  #target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize-address-use-after-return=always")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=float-divide-by-zero")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=implicit-conversion")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=unsigned-integer-overflow")

  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=undefined")
  target_link_options(ProjectCommonFlags INTERFACE "-static-libsan")
endif()

if (DEFINED CONFIG_BUILD_ASAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize-address-use-after-scope")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=address")
  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=address")
endif()

if (DEFINED CONFIG_BUILD_TSAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=thread")
  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=thread")
endif()

if (DEFINED CONFIG_BUILD_LLVM_XRAY)
  target_compile_options(ProjectCommonFlags INTERFACE "-fxray-instrument")
  target_compile_options(ProjectCommonFlags INTERFACE "-fxray-instruction-threshold=1")
  target_link_options(ProjectCommonFlags INTERFACE "-fxray-instrument")
  target_link_options(ProjectCommonFlags INTERFACE "-fxray-instruction-threshold=1")
endif()

if (DEFINED CONFIG_BUILD_MSAN)
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize-memory-track-origins")
  target_compile_options(ProjectCommonFlags INTERFACE "-fsanitize=memory")
  target_link_options(ProjectCommonFlags INTERFACE "-fsanitize=memory")
endif()

