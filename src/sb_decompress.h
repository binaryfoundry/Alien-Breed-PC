/*
 * Alien Breed 3D I - PC Port
 * sb_decompress.h - =SB= (LHA) decompressor
 *
 * The =SB= format is used by AB3D for compressed level data, wall
 * textures, and other assets. It consists of:
 *   bytes 0-3: "=SB=" magic
 *   bytes 4-7: unpacked size (big-endian 32-bit)
 *   bytes 8-11: packed data size (big-endian 32-bit)
 *   bytes 12+: LH5-compressed bitstream
 *
 * Based on lhasa by Simon Howard (ISC license).
 */

#ifndef SB_DECOMPRESS_H
#define SB_DECOMPRESS_H

#include <stdint.h>
#include <stddef.h>

/* Check if a buffer starts with the =SB= magic.
 * Returns 1 if valid, 0 otherwise. */
int sb_is_compressed(const uint8_t *data, size_t data_len);

/* Read the unpacked size from an =SB= header.
 * Returns the unpacked size, or 0 on error. */
uint32_t sb_unpacked_size(const uint8_t *data, size_t data_len);

/* Decompress an =SB= compressed buffer.
 *
 * src      - pointer to the full =SB= data (including 12-byte header)
 * src_len  - length of source data
 * dst      - pointer to output buffer (must be at least sb_unpacked_size bytes)
 * dst_len  - size of output buffer
 *
 * Returns the number of bytes decompressed, or 0 on error.
 */
size_t sb_decompress(const uint8_t *src, size_t src_len,
                     uint8_t *dst, size_t dst_len);

/* Load and decompress an =SB= file from disk.
 *
 * path     - file path
 * out_data - receives malloc'd decompressed data (caller must free)
 * out_size - receives size of decompressed data
 *
 * Returns 0 on success, -1 on error.
 */
int sb_load_file(const char *path, uint8_t **out_data, size_t *out_size);

#endif /* SB_DECOMPRESS_H */
