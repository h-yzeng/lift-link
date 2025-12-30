# Install script for directory: C:/Users/tommy/LiftLink/frontend/windows

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "$<TARGET_FILE_DIR:liftlink>")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Debug")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/tommy/LiftLink/build/flutter/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/tommy/LiftLink/build/runner/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/tommy/LiftLink/build/plugins/app_links/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/tommy/LiftLink/build/plugins/connectivity_plus/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/tommy/LiftLink/build/plugins/sqlite3_flutter_libs/cmake_install.cmake")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for the subdirectory.
  include("C:/Users/tommy/LiftLink/build/plugins/url_launcher_windows/cmake_install.cmake")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Users/tommy/LiftLink/build/runner/liftlink.exe")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner" TYPE EXECUTABLE FILES "C:/Users/tommy/LiftLink/build/runner/liftlink.exe")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Users/tommy/LiftLink/build/runner/data/icudtl.dat")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner/data" TYPE FILE FILES "C:/Users/tommy/LiftLink/frontend/windows/flutter/ephemeral/icudtl.dat")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Users/tommy/LiftLink/build/runner/flutter_windows.dll")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner" TYPE FILE FILES "C:/Users/tommy/LiftLink/frontend/windows/flutter/ephemeral/flutter_windows.dll")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Users/tommy/LiftLink/build/runner/app_links_plugin.dll;C:/Users/tommy/LiftLink/build/runner/connectivity_plus_plugin.dll;C:/Users/tommy/LiftLink/build/runner/sqlite3_flutter_libs_plugin.dll;C:/Users/tommy/LiftLink/build/runner/sqlite3.dll;C:/Users/tommy/LiftLink/build/runner/url_launcher_windows_plugin.dll")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner" TYPE FILE FILES
    "C:/Users/tommy/LiftLink/build/plugins/app_links/app_links_plugin.dll"
    "C:/Users/tommy/LiftLink/build/plugins/connectivity_plus/connectivity_plus_plugin.dll"
    "C:/Users/tommy/LiftLink/build/plugins/sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.dll"
    "C:/Users/tommy/LiftLink/build/plugins/sqlite3_flutter_libs/sqlite3.dll"
    "C:/Users/tommy/LiftLink/build/plugins/url_launcher_windows/url_launcher_windows_plugin.dll"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Users/tommy/LiftLink/build/runner/")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner" TYPE DIRECTORY FILES "C:/Users/tommy/LiftLink/frontend/build/native_assets/windows/")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "C:/Users/tommy/LiftLink/build/runner/data/flutter_assets")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "C:/Users/tommy/LiftLink/build/runner/data/flutter_assets")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner/data" TYPE DIRECTORY FILES "C:/Users/tommy/LiftLink/frontend/build//flutter_assets")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Pp][Rr][Oo][Ff][Ii][Ll][Ee]|[Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/tommy/LiftLink/build/runner/data/app.so")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/tommy/LiftLink/build/runner/data" TYPE FILE FILES "C:/Users/tommy/LiftLink/frontend/build/windows/app.so")
  endif()
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "C:/Users/tommy/LiftLink/build/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
if(CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_COMPONENT MATCHES "^[a-zA-Z0-9_.+-]+$")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
  else()
    string(MD5 CMAKE_INST_COMP_HASH "${CMAKE_INSTALL_COMPONENT}")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INST_COMP_HASH}.txt")
    unset(CMAKE_INST_COMP_HASH)
  endif()
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "C:/Users/tommy/LiftLink/build/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
