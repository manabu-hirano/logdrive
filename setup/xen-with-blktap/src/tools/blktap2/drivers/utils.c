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

#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

#include "utils.h"
#include "preservation.h"

#define DPRINTF(_f, _a...)           syslog(LOG_INFO, _f, ##_a)

uint64_t round_down(uint64_t n, uint64_t unit) {
        return n & ~(unit - 1);
}

uint64_t round_up(uint64_t n, uint64_t unit) {
        return (n + unit - 1) & ~(unit - 1);
}

int bio_init(struct buffered_io *bio, int fd, int read_only, uint64_t next_offset) {
        struct stat st;

        bio->fd = fd;
        bio->read_only = read_only;
        bio->read_buffer_pos = 0;
        bio->read_buffer_enable = 0;
        bio->buffer_pos = 0;
        bio->next_offset = next_offset;

        posix_memalign((void**)&bio->read_buffer, 512, READ_BUFFER_SIZE * sizeof(char));
        if (!read_only) {
                posix_memalign((void**)&bio->buffer, 512, BUFFER_SIZE * sizeof(char));
        }

        return 0;
}

uint64_t bio_finalize(struct buffered_io *bio) {
        bio_flush(bio);

        free(bio->read_buffer);
        free(bio->buffer);

        return bio->next_offset;
}

size_t bio_write(struct buffered_io *bio, const void *buf, size_t size) {
        if (bio->read_only) {
                return 0;
        }
        if (bio->buffer_pos + size > BUFFER_SIZE) {
                /* 書き込もうとしているデータがバッファに収まらない場合、バッファをフラッシュ */
                bio_flush(bio);
        }
        /* バッファにコピー */
        memcpy(bio->buffer + bio->buffer_pos, buf, size);
        bio->buffer_pos += size;
        /* 書き込んだオフセットを返す */
        return bio->next_offset + bio->buffer_pos - size;
}

int bio_read(struct buffered_io *bio, size_t pos, void *buf, size_t size) {
        size_t p = round_down(pos, DEFAULT_SECTOR_SIZE);
        size_t s = round_up(size, DEFAULT_SECTOR_SIZE) + (pos % DEFAULT_SECTOR_SIZE ? DEFAULT_SECTOR_SIZE : 0);
        if (pos >= bio->next_offset) {
                /* ファイルに書き出していない位置を指定された場合、バッファからコピー */
                memcpy(buf, bio->buffer + (pos - bio->next_offset), size);
                return (int)size;
        }
        if (!bio->read_buffer_enable || !(pos >= bio->read_buffer_pos && (pos - bio->read_buffer_pos) + size < READ_BUFFER_SIZE)) {
                /* 読み込みバッファのデータを利用できない場合、ファイルから読み込みバッファに読み込む */
                bio->read_buffer_enable = 1;
                bio->read_buffer_pos = p;
                lseek(bio->fd, p, SEEK_SET);
                if (read(bio->fd, bio->read_buffer, READ_BUFFER_SIZE) == -1) {
                        return -1;
                }
        }
        /* 読み込みバッファからコピー */
        memcpy(buf, bio->read_buffer + (pos - bio->read_buffer_pos), size);
        return (int)size;
}

void bio_flush(struct buffered_io *bio) {
        if (bio->read_only) {
                return;
        }
        if (bio->buffer_pos != 0) {
                size_t size = round_up(bio->buffer_pos, DEFAULT_SECTOR_SIZE);
                
		//DPRINTF("Flushed buffer (size=%d MiB)\n", (int)size/1024);

		lseek(bio->fd, bio->next_offset, SEEK_SET);
                write(bio->fd, bio->buffer, size);
                bio->next_offset += size;
                bio->buffer_pos = 0;
        }
}
