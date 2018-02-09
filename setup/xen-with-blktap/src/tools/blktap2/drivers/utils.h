/*
 * Copyright (C) 2013 Hiromu Ogawa
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#ifndef UTILS_H_INCLUDED
#define UTILS_H_INCLUDED

#include "tapdisk.h"

#define DEFAULT_BLOCK_SIZE 4096
#define READ_BUFFER_SIZE (DEFAULT_BLOCK_SIZE * 2)
#define BUFFER_SIZE ((DEFAULT_BLOCK_SIZE / sizeof(struct entry_header) + 1) * DEFAULT_BLOCK_SIZE)

// We cannot get good performance by using the following buffers
// You just need to open files woithout O_DIRECT that enables OS buffering.
//#define DEFAULT_BLOCK_SIZE 512
//#define MIB 1024*1024
//#define READ_BUFFER_SIZE (DEFAULT_BLOCK_SIZE * 2)  // WE DO NOT NEED READ BUFFER BECAUSE OF INSUFFICIENT IMPLEMENTATION.
//#define BUFFER_SIZE 1024*MIB // WE CAN NOT GET GOOD PERFORMANCE BY USING THIS BUFFER

struct buffered_io {
  int       fd;
  int       read_only;
  char     *read_buffer;
  size_t    read_buffer_pos;
  char      read_buffer_enable;
  char     *buffer;
  int       buffer_pos;
  uint64_t  next_offset;
};

uint64_t round_down(uint64_t n, uint64_t unit);
uint64_t round_up(uint64_t n, uint64_t unit);

int bio_init(struct buffered_io *bio, int fd, int read_only, uint64_t next_offset);

uint64_t bio_finalize(struct buffered_io *bio);

size_t bio_write(struct buffered_io *bio, const void *buf, size_t size);
int bio_read(struct buffered_io *bio, size_t pos, void *buf, size_t size);
void bio_flush(struct buffered_io *bio);

#endif
