cmake_minimum_required(VERSION 3.1.0)
project(fwgen
	VERSION "0.1"
	DESCRIPTION "Binary Firmware Generation Tool"
	LANGUAGES NONE)

if (NOT UNIX)
	message(FATAL_ERROR "UNIX systems with POSIX-shell are only supported")
endif()

# List of fwgen source files
file(GLOB FWGEN_CORE "src/core.sh")
file(GLOB FWGEN_LINK "src/fwgen")
file(GLOB FWGEN_LIBS "src/lib")
file(GLOB FWGEN_FWS "src/fw")

# fwgen installation rules
install(PROGRAMS ${FWGEN_CORE} DESTINATION "/etc/fwgen")
install(FILES ${FWGEN_LINK} DESTINATION bin)
install(DIRECTORY ${FWGEN_LIBS} USE_SOURCE_PERMISSIONS DESTINATION "/etc/fwgen")
install(DIRECTORY ${FWGEN_FWS} USE_SOURCE_PERMISSIONS DESTINATION "/etc/fwgen")
