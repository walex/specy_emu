cmake_minimum_required(VERSION 3.10) # Or your required version


# Enable C/C++ and Assembly languages
project(specy_emu)

set(specy_emu_VERSION 1.0.0)

# c++ 17 as standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if (MSVC)
	enable_language(ASM_MASM)
else(MSVC)
	enable_language(ASM_NASM)
endif(MSVC)
enable_language(C)

# settings for gnu and clang compilers (used on linux and android)
if (CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUXX OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )

	if (${CMAKE_BUILD_TYPE} MATCHES "Debug")

		add_definitions(-DDEBUG)
	else (${CMAKE_BUILD_TYPE} MATCHES "Release")
	
		add_definitions(-DNDEBUG)
	endif (${CMAKE_BUILD_TYPE} MATCHES "Debug")
	 
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
	
endif (CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUXX OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" )

# settings for ms compiler
if (MSVC)
	
	set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /W4 /DDEBUG /EHsc")
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /W4 /EHsc")		
	
endif (MSVC)

find_package(SDL3 REQUIRED CONFIG REQUIRED COMPONENTS SDL3-shared)

file(GLOB SPECY_HEADERS "*.asm" "*.cpp" "*.c")
file(GLOB SPECY_SOURCES "*.inc" "*.h" "*.hpp")

add_subdirectory(./z80)
add_subdirectory(./ula)
add_subdirectory(./video)
add_subdirectory(./storage)
add_subdirectory(./clocks)
add_subdirectory(./audio)
add_subdirectory(./keyboard)
add_subdirectory(./tools)
add_subdirectory(./gui)
add_subdirectory(./os)
add_subdirectory(./spectrum)

set(SPECY_HEADERS ${SPECY_HEADERS} ${CLOCKS_HEADERS} ${ULA_HEADERS} ${VIDEO_RENDER_HEADERS} ${STORAGE_HEADERS} ${AUDIO_HEADERS})
set(SPECY_SOURCES ${SPECY_SOURCES} ${CLOCKS_SOURCES} ${ULA_SOURCES} ${VIDEO_RENDER_SOURCES} ${STORAGE_SOURCES} ${AUDIO_SOURCES})
set(SPECY_HEADERS ${SPECY_HEADERS} ${KEYBOARD_HEADERS} ${TOOLS_HEADERS} ${GUI_HEADERS})
set(SPECY_SOURCES ${SPECY_SOURCES} ${KEYBOARD_SOURCES} ${TOOLS_SOURCES} ${GUI_SOURCES})
set(SPECY_HEADERS ${SPECY_HEADERS} ${OS_HEADERS} ${SPECTRUM_HEADERS})
set(SPECY_SOURCES ${SPECY_SOURCES} ${OS_SOURCES} ${SPECTRUM_SOURCES})

set(SPECY_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${CLOCKS_INCLUDE_DIRS} ${Z80_INCLUDE_DIRS} ${ULA_INCLUDE_DIRS})
set(SPECY_INCLUDE_DIR ${SPECY_INCLUDE_DIR} ${VIDEO_RENDER_INCLUDE_DIRS} ${STORAGE_INCLUDE_DIRS} ${AUDIO_INCLUDE_DIRS})
set(SPECY_INCLUDE_DIR ${SPECY_INCLUDE_DIR} ${KEYBOARD_INCLUDE_DIRS} ${TOOLS_INCLUDE_DIRS} ${GUI_INCLUDE_DIRS})
set(SPECY_INCLUDE_DIR ${SPECY_INCLUDE_DIR} ${OS_INCLUDE_DIRS} ${SPECTRUM_INCLUDE_DIRS})

add_library(z80_emu STATIC ${Z80_SOURCES} ${Z80_HEADERS})
target_compile_options(z80_emu PRIVATE /I${Z80_CPU_INCLUDE_DIRS} /I${CLOCKS_INCLUDE_DIRS} /I${ULA_INCLUDE_DIRS} /I${Z80_TOOLS_INCLUDE_DIRS} /I${OS_INCLUDE_DIRS})

add_executable(specy_emu ${SPECY_SOURCES} ${SPECY_HEADERS})
target_include_directories(specy_emu PRIVATE ${SPECY_INCLUDE_DIR})
target_link_libraries(specy_emu PRIVATE z80_emu SDL3::SDL3)
add_custom_command(TARGET specy_emu POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_PROPERTY:SDL3::SDL3-shared,IMPORTED_LOCATION>"
        $<TARGET_FILE_DIR:specy_emu>
)
add_custom_command(
    TARGET specy_emu
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_SOURCE_DIR}/roms"
            "$<TARGET_FILE_DIR:specy_emu>/roms"
)

add_executable(z80_unit_tests ${Z80_UNIT_TESTS_SOURCES} ${ULA_SOURCES} ${ULA_HEADERS})
target_include_directories(z80_unit_tests PRIVATE ${Z80_INCLUDE_DIRS} ${ULA_INCLUDE_DIRS})
target_link_libraries(z80_unit_tests PRIVATE z80_emu)