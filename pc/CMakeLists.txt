cmake_minimum_required(VERSION 3.16)
project(ab3d1 C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# -----------------------------------------------------------------------
# SDL2 (auto-download via FetchContent)
# -----------------------------------------------------------------------
include(FetchContent)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
set(SDL2_DISABLE_INSTALL ON CACHE BOOL "" FORCE)

FetchContent_Declare(
    SDL2
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG        release-2.30.11
    GIT_SHALLOW    TRUE
)
FetchContent_MakeAvailable(SDL2)

# All source files
set(SOURCES
    src/main.c
    src/game_state.c
    src/game_data.c
    src/math_tables.c
    src/ai.c
    src/movement.c
    src/level.c
    src/objects.c
    src/visibility.c
    src/control_loop.c
    src/game_loop.c
    src/player.c
    src/renderer.c
    src/stub_display.c
    src/stub_input.c
    src/stub_audio.c
    src/stub_io.c
    src/sb_decompress.c
)

add_executable(ab3d1 ${SOURCES})

target_include_directories(ab3d1 PRIVATE src)

# Link SDL2 (no SDL2main - we use CONSOLE subsystem for printf output)
target_link_libraries(ab3d1 PRIVATE SDL2-static)

# Platform-specific settings
if(WIN32)
    # Windows: link winmm for SDL2
    target_link_libraries(ab3d1 PRIVATE winmm imm32 version setupapi)
elseif(UNIX)
    target_link_libraries(ab3d1 PRIVATE m)
endif()

# Debug build by default for development
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Force CONSOLE subsystem on Windows (override SDL2's WINDOWS subsystem)
if(MSVC)
    target_link_options(ab3d1 PRIVATE /SUBSYSTEM:CONSOLE)
endif()

# Warnings
if(MSVC)
    target_compile_options(ab3d1 PRIVATE /W4)
    target_compile_definitions(ab3d1 PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
    target_compile_options(ab3d1 PRIVATE -Wall -Wextra -Wpedantic)
endif()
