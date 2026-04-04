# Alien Breed 3D I (PC Port)

A C port of Alien Breed 3D I (Amiga), translating the original 68000 assembly into C and rendering with SDL2 on Windows, Linux, and macOS.

The project keeps Amiga data formats and game behavior where possible, while running natively on modern platforms.

![Alien Breed HD Image](docs/alien.jpg)

---

## Repository layout

- Root: PC port source and build system (`src/`, `tools/`, `CMakeLists.txt`).
- `data/`: Working data directory used by tooling and runtime fallbacks.
- `amiga/`: Original Amiga assembly sources and source-asset directories used by build sync steps.

---

## What this project includes

- Original Amiga 68000 source for reference (`amiga/`).
- Native C reimplementation of gameplay/rendering/runtime systems (`src/`).
- SDL2-based platform layer for display, input, and audio output.

No Amiga binary is executed by this port.

---

## Game data and build pipeline

Game data is synchronized by CMake from `amiga/` into `data/`, then copied beside the built executable.

Configure-time syncs:

- `amiga/pal` and `amiga/data/pal` -> `data/pal`
- `amiga/data/gfx` -> `data/gfx`
- `amiga/data/includes` -> `data/includes`
- `amiga/data/levels` -> `data/levels`

Post-build copies to output (`$<TARGET_FILE_DIR:ab3d1>/data/...`):

- `data/gfx`
- `data/includes`
- `data/levels`
- `data/sounds`
- `amiga/vectorobjects` -> `data/vectorobjects`

Sound conversion pipeline:

1. `amiga/sounds` is synced to `data/sounds`.
2. `tools/raw_to_wav.py` generates `.wav` files in `data/sounds`.
3. `data/sounds` is copied beside the executable.

Notes:

- Runtime still supports raw Amiga sound files; `.wav` generation is build convenience.
- If source assets are not present in your checkout, provide your own legally obtained data.

---

## Build

### Requirements

- CMake 3.16+
- C11 compiler (MSVC, GCC, or Clang)
- Python 3 (used by asset helper scripts)
- Network access during first configure (SDL2 is fetched via CMake FetchContent)

### Commands

From repository root:

```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

Typical outputs:

- Windows: `build/Release/ab3d1.exe`
- Linux/macOS: `build/ab3d1`

---

## Run

Run from the build output location (or repo root if you prefer):

```bash
# Windows
build/Release/ab3d1.exe

# Linux/macOS
./build/ab3d1
```

---

## References

- Original Team17 source archive: [alienbreed3dii](https://github.com/videogamepreservation/alienbreed3dii.git)
- RTG variant: [ab3d-rtg](https://github.com/mheyer32/ab3d-rtg)
- VS Code extension for Amiga assembly: [prb28.amiga-assembly](https://marketplace.visualstudio.com/items?itemName=prb28.amiga-assembly)
