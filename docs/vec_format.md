# Amiga .vec vector object format

This document describes the binary layout of Amiga 3D vector objects (`.vec` files) used by `PolygonObj` in `amiga/ObjDraw3.ChipRam.s`. All multi-byte values are **big-endian**.

## File layout (top level)

| Offset | Size | Name          | Description |
|--------|------|---------------|-------------|
| 0      | 2    | num_points    | Number of 3D points per frame |
| 2      | 2    | num_frames    | Number of animation frames |
| 4      | 2*N  | frame_offsets  | N = num_frames. Each word is byte offset from start of object to that frame’s point data (x,y,z words per point, 6 bytes per point). |
| 4+2*N  | …    | part_list     | See below. Terminated by part entry -1 (0xFFFF). |
| …      | …    | frame_data    | For each frame, num_points × (x, y, z) as three int16 words (6 bytes per point). |

So `part_list` starts at byte `4 + 2*num_frames`. The first frame’s point data starts at the byte offset given by `frame_offsets[0]`.

## Part list

Each part entry is 4 bytes:

- **Word 0**: Byte offset from **start of this vector object** to this part’s polygon data.
- **Word 1**: Sort point index (index into the object’s point array) used for depth-sorting parts (e.g. centroid or representative vertex).

The list ends with a part entry equal to **-1** (0xFFFF, 0xFFFF). The high word is the terminator; the Amiga code checks `blt doneallparts` on the first word.

## Polygon data (per part)

Each part’s data is a sequence of **polygon records**. The next polygon is reached by advancing by `18 + (lines_to_draw * 4)` bytes from the start of the current record. The list ends when the first word of a record is **&lt; 0** (e.g. -1).

### Polygon record layout

| Offset     | Size     | Name           | Description |
|------------|----------|----------------|-------------|
| 0         | 2        | lines_to_draw  | Number of vertices (3 = triangle, 4 = quad). Terminator if &lt; 0. |
| 2         | 2        | preholes       | Hole / flag word (used by doapoly). |
| 4         | 2*V      | vertex_indices | V = lines_to_draw. Vertex indices into the object’s point array (screen-space points in `boxonscr` at draw time). |
| 4+2*V     | 2        | texture_offs   | Word offset into TextureMaps for this polygon. |
| 6+2*V     | 2        | divisor        | Used for brightness/scale in doapoly. |
| …         | …        | (pregour etc.) | At 12+lines_to_draw*4 there is a word used for Gouraud (pregour). |

Record length in bytes: **18 + (lines_to_draw * 4)**.

## Frame data

For each frame `f`, the points for that frame start at byte offset `frame_offsets[f]`. There are `num_points` points, each stored as three **int16** words: **x**, **y**, **z** (object-space). Total size per frame: **num_points * 6** bytes.

## POLYOBJECTS table (Amiga)

In `ObjDraw3.ChipRam.s`, `POLYOBJECTS` is a table of 10 longword pointers to vector objects:

| Index | Label       | Source file              |
|-------|-------------|---------------------------|
| 0     | spider_des  | vectorobjects/robot.vec   |
| 1     | medi_des   | vectorobjects/medipac.vec |
| 2     | exit_des   | vectorobjects/exitsign.vec |
| 3     | crate_des  | vectorobjects/crate.vec  |
| 4     | terminal_des | vectorobjects/terminal.vec |
| 5     | blue_des   | vectorobjects/blueind.vec |
| 6     | green_des  | vectorobjects/Greenind.vec |
| 7     | red_des    | vectorobjects/Redind.vec  |
| 8     | yellow_des | vectorobjects/YellowInd.vec.s (or yellowind.vec) |
| 9     | gas_des    | vectorobjects/gaspipe.vec |

## .vec.s (assembly) variant

Some objects are included as assembly (e.g. `YellowInd.vec.s`) with `dc.b $XX,$YY` lines. The binary content is the same as a .vec file: the same byte stream. A converter can either parse the hex bytes from `.vec.s` or use pre-assembled binary `.vec` for those files.

## Limits (for PC port)

- **MAX_POLY_POINTS**: e.g. 250 (Amiga uses 250 in boxrot/boxonscr).
- **MAX_POLY_FRAMES**: e.g. 32.
- **MAX_POLY_PARTS**: e.g. 32 (Amiga PartBuffer is 2*32 words).
- **MAX_POLY_VERTICES**: 4 (tri or quad per polygon record).
