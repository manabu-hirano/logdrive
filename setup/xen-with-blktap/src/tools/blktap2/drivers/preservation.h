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

#ifndef PRESERVATION_H_INCLUDED
#define PRESERVATION_H_INCLUDED

#include <sys/time.h>
#include <stdint.h>
#include <stdlib.h>

#include "tapdisk.h"
#include "utils.h"

#define MAX_BLOCKS_PER_REQUEST 8
typedef unsigned short data_size_t;

struct data_header {
  size_t    disk_size; // in byte (1KiB=2^10,1MiB=2^20,...)
  uint64_t  block_size; // in byte (typical value is 4096)
  uint64_t  next_offset; // byte offset in the preservation file
};

struct entry_header {
  struct timespec ts;
  uint64_t        next;
  data_size_t     data_size;
  /* char data[data_size]; */
};

struct preservation_disk {
        struct data_header *header;

        int                 fd;
        struct buffered_io  bio;

        int                 read_only;

        struct timespec     ts;

        uint64_t            sector_count;
        uint64_t            sectors_per_block;

        uint64_t           *index_table;

        char               *index_cache_enable;
        data_size_t        *cached_data_size;
};

int pd_initialize(struct preservation_disk *disk, const char *name);
int pd_initialize_read_only(struct preservation_disk *disk, const char *name, const struct timespec *ts);

void pd_finalize(struct preservation_disk *disk);

void pd_set_driver_info(struct preservation_disk *disk, td_disk_info_t *info);

int pd_write(struct preservation_disk *disk, td_request_t *request);
int pd_read(struct preservation_disk *disk, td_request_t *request);

#endif
