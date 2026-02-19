# Alien Breed 3D I

C port of **Alien Breed 3D** (Amiga), with original Amiga assembly sources for reference.

## Repository layout

- **Root** – PC port (C + SDL2): `src/`, `data/`, `tools/`, build from here with CMake.
- **`amiga/`** – Original Amiga 68000 assembly (`.s`), includes, and reference assets. See [amiga/README.md](amiga/README.md) for data extraction and build/run instructions that refer to the root `data/` and build output.

## Quick start (PC port)

From the repository root:

```bash
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

Put game data in **`data/`** (see [amiga/README.md](amiga/README.md) for how to get it from the original game). Run from the repo root so the executable finds `data/`:

```bash
build/Release/ab3d1.exe   # Windows
./build/ab3d1             # Linux/macOS
```

Full details (requirements, data layout, controls) are in [amiga/README.md](amiga/README.md).
