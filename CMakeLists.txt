cmake_minimum_required(VERSION 3.18)
set(CURRENT_BASE_PATH "${CMAKE_CURRENT_LIST_DIR}")

if (NOT CMAKE_C_COMPILER_ID MATCHES "Clang")
  message(FATAL_ERROR "Non clang compiler unsupported")
endif()

include(build.cmake)
include(${CURRENT_BASE_PATH}/util.cmake)

PreConfigurationLoad()
include(${CURRENT_BASE_PATH}/scripts/process_dot_config.cmake)
PostConfigurationLoad()

# Source of truth for version is 
# NOT HERE its in Kconfig file
project(${BUILD_PROJECT_NAME} VERSION 1.0.0
       LANGUAGES ${BUILD_LANG})
       
# C standard checks
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Suppression files (abusing configure)
configure_file(
  ${PROJECT_SOURCE_DIR}/suppressions/UBSan.supp 
  ${PROJECT_BINARY_DIR}/suppressions/UBSan.supp
)

util_protobuf_generate_c(PROTO_SRC PROTO_HEADERS ${BUILD_PROTOBUF_FILES})
include(${CURRENT_BASE_PATH}/scripts/compiler_and_link_flags.cmake)

set(BUILD_LIB_NAME ${PROJECT_NAME})
set(BUILD_LIB_NAME_STATIC ${PROJECT_NAME}_Static)
set(BUILD_EXE_NAME ${PROJECT_NAME}_${CONFIG_VERSION_MAJOR}.${CONFIG_VERSION_MINOR})

configure_file(src/config.h src/processed_config.h)
configure_file(${PROJECT_SOURCE_DIR}/.config ${PROJECT_BINARY_DIR}/.config)

add_library(Project_Objects OBJECT ${BUILD_SOURCES} ${PROTO_SRC})

find_package(PkgConfig REQUIRED)
function (AddPkgConfigLib name spec)
  if (DEFINED CONFIG_BUILD_IS_KERNEL)
    message(FATAL "Not available in kernel compilation")
  endif()
  
  pkg_check_modules(${name} REQUIRED ${spec})
  target_link_libraries(ProjectCommonFlags INTERFACE ${${name}_LIBRARIES})
  target_include_directories(ProjectCommonFlags INTERFACE ${${name}_INCLUDE_DIRS})
  target_compile_options(ProjectCommonFlags INTERFACE ${${name}_CFLAGS_OTHER})
endfunction()

target_link_libraries(Project_Objects ProjectCommonFlags)
AddDependencies()

if (DEFINED CONFIG_BUILD_IS_LIBRARY)
  add_library(${BUILD_LIB_NAME} SHARED)
  add_library(${BUILD_LIB_NAME_STATIC} STATIC)

  set_target_properties(${BUILD_LIB_NAME}
    PROPERTIES
    VERSION ${CONFIG_VERSION_MAJOR}.${CONFIG_VERSION_MINOR}.${CONFIG_VERSION_PATCH}${VERSION_LOCAL_VERSION}
    SOVERSION ${CONFIG_VERSION_MAJOR}
  )
  
  target_link_libraries(${BUILD_LIB_NAME} Project_Objects)
  target_link_libraries(${BUILD_LIB_NAME_STATIC} Project_Objects)
endif()
###############

add_executable(Executable ${BUILD_EXE_SOURCES})
target_link_libraries(Executable ProjectCommonFlags)
target_link_libraries(Executable Project_Objects)

# Installation section
include(GNUInstallDirs)

if (DEFINED CONFIG_BUILD_INSTALL_EXECUTABLE)
  add_custom_command(
    TARGET Executable POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy
      $<TARGET_FILE:Executable>
      ${PROJECT_BINARY_DIR}/${BUILD_EXE_NAME}
  )

  install(
    FILES ${PROJECT_BINARY_DIR}/${BUILD_EXE_NAME}
    DESTINATION ${CMAKE_INSTALL_BINDIR}/
    PERMISSIONS 
      WORLD_READ    GROUP_READ    OWNER_READ      
                                  OWNER_WRITE
      WORLD_EXECUTE GROUP_EXECUTE OWNER_EXECUTE
  )
endif()

if (DEFINED CONFIG_BUILD_IS_LIBRARY) 
  # Install library
  install(
    TARGETS ${BUILD_LIB_NAME}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/
    PERMISSIONS
      WORLD_READ    GROUP_READ    OWNER_READ      
                                  OWNER_WRITE
      WORLD_EXECUTE GROUP_EXECUTE OWNER_EXECUTE
  )
  install(
    TARGETS ${BUILD_LIB_NAME_STATIC}
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/
    PERMISSIONS
      WORLD_READ    GROUP_READ    OWNER_READ      
                                  OWNER_WRITE
      WORLD_EXECUTE GROUP_EXECUTE OWNER_EXECUTE
  )

  if (DEFINED CONFIG_BUILD_INSTALL_PKGCONFIG)
    # Install pkgconfig file
    set(PKGCONFIG_NAME ${CURRENT_BASE_PATH}/package.pc.in)

    # Use project's pkgconfig instead 
    # buildsystem provided
    if (EXISTS ${PROJECT_SOURCE_DIR}/package.pc.in)
      set(PKGCONFIG_NAME ${PROJECT_SOURCE_DIR}/package.pc.in)  
    endif()

    configure_file(${PKGCONFIG_NAME}
      ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc @ONLY)
    install(
      FILES ${CMAKE_BINARY_DIR}/${PROJECT_NAME}.pc
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig/
    )
  endif()
endif()

if (DEFINED CONFIG_BUILD_INSTALL_HEADERS)
  # Install library headers
  install(
    FILES ${BUILD_PUBLIC_HEADERS}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
  )
endif()





