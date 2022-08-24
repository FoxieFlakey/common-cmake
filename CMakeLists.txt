cmake_minimum_required(VERSION 3.18)

# Needed
cmake_policy(SET CMP0048 NEW)

include(build.cmake)
set(CURRENT_BASE_PATH "${CMAKE_CURRENT_LIST_DIR}")

# Source of truth for version is 
# NOT HERE its in Kconfig file
project(${BUILD_PROJECT_NAME} VERSION 1.0.0
                 LANGUAGES C)

if (NOT CMAKE_C_COMPILER_ID MATCHES "Clang")
  message(FATAL_ERROR "Non clang compiler unsupported")
endif()

# C standard checks
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Suppression files (abusing configure)
configure_file(
  ${PROJECT_SOURCE_DIR}/suppressions/UBSan.supp 
  ${PROJECT_BINARY_DIR}/suppressions/UBSan.supp
)

include(${CURRENT_BASE_PATH}/scripts/process_dot_config.cmake)
include(${CURRENT_BASE_PATH}/scripts/compiler_and_link_flags.cmake)

set(BUILD_LIB_NAME ${PROJECT_NAME})
set(BUILD_EXE_NAME ${PROJECT_NAME}_${CONFIG_VERSION_MAJOR}.${CONFIG_VERSION_MINOR})

configure_file(src/config.h src/processed_config.h)
configure_file(${PROJECT_SOURCE_DIR}/.config ${PROJECT_BINARY_DIR}/.config)

add_library(Project_Objects OBJECT ${BUILD_SOURCES})

find_package(PkgConfig REQUIRED)
function (AddPkgConfigLib name spec)
  pkg_check_modules(${name} REQUIRED ${spec})
  target_link_libraries(ProjectCommonFlags INTERFACE ${${name}_LIBRARIES})
  target_include_directories(ProjectCommonFlags INTERFACE ${${name}_INCLUDE_DIRS})
  target_compile_options(ProjectCommonFlags INTERFACE ${${name}_CFLAGS_OTHER})
endfunction()

## Deps here ##
target_link_libraries(Project_Objects ProjectCommonFlags)
AddDependencies()

if (BUILD_IS_LIBRARY)
  add_library(${BUILD_LIB_NAME} SHARED)

  set_target_properties(${BUILD_LIB_NAME}
    PROPERTIES
    VERSION ${CONFIG_VERSION_MAJOR}.${CONFIG_VERSION_MINOR}.${CONFIG_VERSION_PATCH}${VERSION_LOCAL_VERSION}
    SOVERSION ${CONFIG_VERSION_MAJOR}
  )
  
  target_link_libraries(${BUILD_LIB_NAME} Project_Objects)
endif()
###############

add_executable(Executable ${BUILD_EXE_SOURCES})
target_link_libraries(Executable ProjectCommonFlags)
target_link_libraries(Executable Project_Objects)

include(GNUInstallDirs)

if (BUILD_INSTALL_EXECUTABLE)
  #get_property(a TARGET Executable PROPERTY LOCATION)
  #message(${a})
  install(
    FILES $<TARGET_FILE:Executable>
    DESTINATION ${CMAKE_INSTALL_BINDIR}/${BUILD_EXE_NAME}
    PERMISSIONS 
      WORLD_READ    GROUP_READ    OWNER_READ      
                                  OWNER_WRITE
      WORLD_EXECUTE GROUP_EXECUTE OWNER_EXECUTE
  )
endif()

if (BUILD_IS_LIBRARY) 
  # Install library headers
  install(
    FILES ${BUILD_PUBLIC_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
  )

  # Install library
  install(
    TARGETS ${BUILD_LIB_NAME}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/
    PERMISSIONS
      WORLD_READ    GROUP_READ    OWNER_READ      
                                  OWNER_WRITE
      WORLD_EXECUTE GROUP_EXECUTE OWNER_EXECUTE
  )

  # Install pkgconfig file
  configure_file(package.pc.in
    ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc @ONLY)
  install(
    FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig/
  )
endif()






