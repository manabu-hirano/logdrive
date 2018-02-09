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
 * Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/statvfs.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <limits.h>
#include <memory.h>
#include "utils.h"
#include "preservation.h"
#include <ctype.h> //append


#define DEBUG_IO
extern void print_io(char*, char*, td_sector_t, int, int, int);
extern void print_hex(unsigned char*, int, int, int);

#define ROUND_UPPED_DATA_HEADER_SIZE ((sizeof(struct data_header) + DEFAULT_SECTOR_SIZE - 1) & ~(DEFAULT_SECTOR_SIZE - 1))

/**
 * ヘッダを読み込む
 */
static int read_header(struct preservation_disk *disk) {
        int result;

        DPRINTF("read_header\n");

        result = read(disk->fd, disk->header, ROUND_UPPED_DATA_HEADER_SIZE);

        DPRINTF("header->disk_size: %"PRIu64"\n", disk->header->disk_size);
        DPRINTF("header->block_size: %d\n", (int)disk->header->block_size);
        DPRINTF("header->next_offset: %"PRIu64"\n", disk->header->next_offset);

        return result;
}

/**
 * ヘッダを書き込む
 */
static int write_header(struct preservation_disk *disk) {
        int result;

        DPRINTF("write_header\n");
        DPRINTF("header->disk_size: %"PRIu64"\n", disk->header->disk_size);
        DPRINTF("header->block_size: %d\n", (int)disk->header->block_size);
        DPRINTF("header->next_offset: %"PRIu64"\n", disk->header->next_offset);

        lseek(disk->fd, 0, SEEK_SET);
        result = write(disk->fd, disk->header, ROUND_UPPED_DATA_HEADER_SIZE);

        return result;
}

static int open_disk(struct preservation_disk *disk, const char *name, int read_only) {
        size_t index_table_size;
        int fd;
	
	//
	// Current setting of O_DIRECT in preservation.c
	//
#define O_DIRECT_FOR_PRSV 0  // O_DIRECT setting for PRSV (1:on, 0:off)

	if ( O_DIRECT_FOR_PRSV ) {
       	  fd = open(name, (read_only ? O_RDONLY : O_RDWR) | O_NOATIME | O_DIRECT); 
          DPRINTF("open_disk name:%s read_only:%d with O_DIRECT\n", name, read_only);
        } else { 
	  fd = open(name, (read_only ? O_RDONLY : O_RDWR) | O_NOATIME ); 
          DPRINTF("open_disk name:%s read_only:%d without O_DIRECT\n", name, read_only);
        }
	if (fd == -1) {
                return -1;
        }

        disk->fd = fd;
        disk->read_only = read_only;

        posix_memalign((void**)&disk->header, DEFAULT_SECTOR_SIZE, ROUND_UPPED_DATA_HEADER_SIZE);
        read_header(disk);

        disk->sectors_per_block = disk->header->block_size / DEFAULT_SECTOR_SIZE;
        
	DPRINTF("sectors_per_block: %"PRIu64"\n", disk->sectors_per_block);

        bio_init(&disk->bio, fd, read_only, disk->header->next_offset);

        index_table_size = round_up(disk->header->disk_size / disk->header->block_size * sizeof(uint64_t), DEFAULT_SECTOR_SIZE);

	DPRINTF("index_table_size: %zd\n", index_table_size);
	
        posix_memalign((void**)&disk->index_table, DEFAULT_SECTOR_SIZE, index_table_size);
        memset(disk->index_table, 0, index_table_size);
        read(fd, disk->index_table, index_table_size);
	
        if (read_only) {
                disk->index_cache_enable = calloc(round_up(disk->header->disk_size / disk->header->block_size, CHAR_BIT), sizeof(char));
                disk->cached_data_size = calloc(disk->header->disk_size / disk->header->block_size, sizeof(data_size_t));
		DPRINTF("index_cache_enable (for checking if the cache is set or not on the block): calloc char array[%zd]\n", round_up(disk->header->disk_size / disk->header->block_size, CHAR_BIT));
		DPRINTF("cached_data_size (for storing data_size of each block): calloc unsigned short array[%zd]\n", disk->header->disk_size / disk->header->block_size);

        }

        return 0;
}

int pd_initialize(struct preservation_disk *disk, const char *name) {
        int result;

        DPRINTF("pd_initialize\n");

        result = open_disk(disk, name, 0);
        return result;
}

int pd_initialize_read_only(struct preservation_disk *disk, const char *name, const struct timespec *ts) {
        int result;

        DPRINTF("pd_initialize_read_only\n");

        result = open_disk(disk, name, 1);
        memcpy(&disk->ts, ts, sizeof(struct timespec));
        return result;
}

void pd_set_driver_info(struct preservation_disk *disk, td_disk_info_t *info) {
        DPRINTF("pd_set_driver_info\n");

        info->size = disk->header->disk_size >> SECTOR_SHIFT;
        info->sector_size = DEFAULT_SECTOR_SIZE;
        info->info = 0;

        DPRINTF("info->size: %"PRIu64"\n", info->size);
        DPRINTF("info->sector_size: %"PRIu64"\n", info->sector_size);
}

void pd_finalize(struct preservation_disk *disk) {
        uint64_t offset;

        DPRINTF("pd_finalize\n");

        offset = bio_finalize(&disk->bio);

        if (!disk->read_only) {
                size_t index_table_size = 
		  round_up(disk->header->disk_size / disk->header->block_size * sizeof(uint64_t), 
			   DEFAULT_SECTOR_SIZE);

                /* ヘッダを書き込む */
                disk->header->next_offset = offset;
                write_header(disk);

                /* 索引を書き込む */
                lseek(disk->fd, ROUND_UPPED_DATA_HEADER_SIZE, SEEK_SET);
                write(disk->fd, disk->index_table, index_table_size);
        }

        close(disk->fd);

        free(disk->index_table);
        if (disk->read_only) {
	  free(disk->index_cache_enable);
	  free(disk->cached_data_size);
        }
}

/**
 * slack space を除いた実質的なデータのサイズを数える
 */
static size_t get_actual_data_size(struct preservation_disk *disk, const char *buf) {
        size_t i;
        size_t block_size = disk->header->block_size;
        size_t result = block_size;
        for (i = 0; i < block_size; ++i) {
	  if (buf[result - 1] != 0) {
	    // Align 16 byte boundary
	    // 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	    // 16,17, ...                         31
	    // result(size)=0,16->0, 1,17-> 16,32, 15,31->16,32
	    if (result % 16 != 0) {
	      result += (16-result%16);
	    }
	    return result;
	  }
	  --result;
        }
        return 0;
}


typedef int (*read_block_t)(struct preservation_disk*, char*, uint64_t);

void print_hex(unsigned char *buf, int data_size, int offset, int printall) {
        int j,k,l;
	char io_data[1024];
	char *io_data_p;
	char io_data_ascii[1024];
	char *io_data_ascii_p;
	char tmp[2];
  
	// 表示文字列用バッファを初期化
	for(j=0;j<1024;j++){
	  io_data[j] = '\0';
	  io_data_ascii[j] = '\0';
	}
	
	// データ部分を１行ずつ出力する
	for(j=0; j<data_size; j++) {
	  io_data_p = io_data;
	  io_data_ascii_p = io_data_ascii;

	  if( offset == -1 ) {
	    // for header
	    sprintf(io_data_p, "               ");  
	    io_data_p+=15;
	  } else {
	    // for data entries
	    sprintf(io_data_p, "%014d ", offset + j );  
	    io_data_p+=15;
	  }

	  l=0;
	  for(k=0; k<16; k++) {
	    if( (unsigned char)(buf[j+k]) != 0 ) l=1;
	    if( k%2==0 && k!=0 ) { 
	      // swap for endian
	      tmp[0] = *(io_data_p-4);
	      tmp[1] = *(io_data_p-3);
	      *(io_data_p-4) = *(io_data_p-2);
	      *(io_data_p-3) = *(io_data_p-1);
	      *(io_data_p-2) = tmp[0];
	      *(io_data_p-1) = tmp[1];

	      *io_data_p = ' '; io_data_p++; 
	    }
	    sprintf(io_data_p,"%02x", (unsigned char)(buf[j+k]) );
	    io_data_p+=2;
	    sprintf(io_data_ascii_p,"%1c", isprint((unsigned char)(buf[j+k])) == 0 ?
		    '.' : (unsigned char)(buf[j+k]));
	    io_data_ascii_p++;
	  }
	  if( k==16 ) { j+=15; } else { j = j+k; }

	  // swap for endian
	  tmp[0] = *(io_data_p-4);
	  tmp[1] = *(io_data_p-3);
	  *(io_data_p-4) = *(io_data_p-2);
	  *(io_data_p-3) = *(io_data_p-1);
	  *(io_data_p-2) = tmp[0];
	  *(io_data_p-1) = tmp[1];

	  sprintf(io_data_p, " %s", io_data_ascii);
	  // データの1行を出力する
	  if( l==1 || printall ) 
	    { DPRINTF("%s", io_data);}
	}

}

/**
 * ヘッダ情報をデバッグ表示する
 */
void print_header(struct entry_header *header) {
  time_t tvsec = (header->ts).tv_sec;
  struct tm *ltime;
  ltime = localtime(&tvsec);
  DPRINTF("test: header ts=%lld(%s), data_size=%5d, next=%"PRIu64"", 
	  (long long)tvsec, asctime(ltime), header->data_size, header->next);  

  print_hex((unsigned char*) header, sizeof(struct entry_header), -1, 1);
  
}

/**
 * 入出力データをデバッグ表示する
 */
void print_io(char *buf, char *type, td_sector_t sec, int secs, int block, int actual_size) {
  int data_size = secs * DEFAULT_SECTOR_SIZE;
  int offset_byte = sec * DEFAULT_SECTOR_SIZE;

  if(actual_size==0) {
    actual_size = data_size;
  }
  // デバッグ用のデータ出力
  DPRINTF("test: %s on block %d, requested_offset=%10d[byte](%5"PRIu64"[sector]), requested_size=%5d [byte](%1d[sector]) actual_size=%5d[byte]", type, block, offset_byte, sec, data_size, secs, actual_size);

  // データ出力
  // print_hex((unsigned char*)buf, actual_size, offset_byte, 0);  
    
}

/**
 * ブロックの指定時刻の状態を読み込む
 */
  static int read_current_block(struct preservation_disk *disk, char *buf, uint64_t block) {
        uint64_t offset;
        size_t data_size;
        size_t block_size = disk->header->block_size;

        offset = disk->index_table[block];

	// キャッシュ（オフセットとデータサイズ）を確認
        if ((disk->index_cache_enable[block / CHAR_BIT] & (1 << (block % CHAR_BIT))) == 0) {
	  /* キャッシュが存在しない場合 */
	  struct entry_header header;
	  struct timespec *ts = &disk->ts;
	  while (offset) {
	    /* リストを探索 */
	    bio_read(&disk->bio, offset, &header, sizeof(struct entry_header));
	    data_size = header.data_size;
	    if (header.ts.tv_sec < ts->tv_sec || (header.ts.tv_sec == ts->tv_sec && header.ts.tv_nsec < ts->tv_nsec)) {
	      break;
	    }
	    offset = header.next;
	  }
	  /* キャッシュを設定 */
	  disk->index_table[block] = offset;
	  disk->index_cache_enable[block / CHAR_BIT] |= (1 << (block % CHAR_BIT));
	  disk->cached_data_size[block] = data_size;
        }
        else {
	  /* キャッシュが存在する場合 */
	  data_size = disk->cached_data_size[block];
        }
	
	// データの読み込み
        if (offset != 0 && data_size > 0) {
	  bio_read(&disk->bio, offset + sizeof(struct entry_header), buf, data_size);
	  memset(buf + data_size, 0, block_size - data_size);
        }
        else {
	  memset(buf, 0, block_size);
        }

        return 0;
}

/**
 * ブロックの最新の状態を読み込む
 */
static int read_latest_block(struct preservation_disk *disk, char *buf, uint64_t block) {
        struct entry_header header;
        uint64_t offset = disk->index_table[block];
        size_t block_size = disk->header->block_size;
        size_t data_size;

	// エントリの存在を確認
        if (!offset) {
	  // エントリがないので１ブロックをゼロで埋める
	  memset(buf, 0, block_size);
        } else {
	  // エントリのデータサイズの確認
	  bio_read(&disk->bio, offset, &header, sizeof(struct entry_header));
	  data_size = header.data_size;
	  if (data_size == 0) {
	    // エントリがあり、かつエントリデータサイズがゼロのときゼロで埋める
	    memset(buf, 0, block_size);
	  } else {
	    // エントリがあり、かつデータサイズが非ゼロのとき、データを読み込む
	    bio_read(&disk->bio, offset + sizeof(struct entry_header), buf, data_size);
	    // 残りをゼロで埋める
	    memset(buf + data_size, 0, block_size - data_size);
	  }
	}
        return 0;
}

int pd_read(struct preservation_disk *disk, td_request_t *treq) {
        size_t block_size = disk->header->block_size;
        read_block_t read_block = disk->read_only ? read_current_block : read_latest_block;
	
	// treq->sec  読み込み開始セクタ番号(512バイト=1セクタ ex. sec=2 のとき 1024 byte目から読み込む）
	// sectors_per_block 4096バイト＝１ブロックのとき、１ブロック=8セクタ
	// treq->secs 読み込みをするセクタ数(512バイト=1セクタ, ex. secs=2 のとき 1024 byte を読み込む）
	
	// DPRINTF("prsv: pd_read() for treq->sec=%"PRIu64", treq->secs=%"PRIu32"", treq->sec, treq->secs);
        
	if (treq->sec % disk->sectors_per_block == 0 && treq->secs % disk->sectors_per_block == 0) {
	  /* 要求がブロック単位だった場合 */
	  size_t i;
	  uint64_t block;
	  size_t blocks = treq->secs / disk->sectors_per_block;
	  
	  for (i = 0; i < blocks; ++i) {
	    block = treq->sec / disk->sectors_per_block + i;
	    
	    if (read_block(disk, treq->buf + (i * block_size), block) == -1) {
	      DPRINTF("Failed to read_block (per block)");
	      return -1;
	    }
	  }
	  //print_io(treq->buf, "read(p/b)", treq->sec, treq->secs, block, 0);
	  return 0;
        }
        else {
	  /* 要求がブロック単位でなかった場合 */
	  size_t i,l;
	  uint64_t sector;
	  uint64_t block;
	  int read_blocks;
	  // ブロック境界をまたいだとしても、
	  // 最大で１ブロックまでを読み込むことを想定
	  // つまり最大２ブロック分のバッファを確保
	  char buf[DEFAULT_BLOCK_SIZE*2]={};
	  
	  // treq->sec から treq->secs 分のセクタを読み込む
	  // 0  1  2  3  4  5  6  7
	  // 8  9 10 11 12 13 14 15
	  sector = treq->sec;
	  read_blocks = 0;
	  while ( sector < (treq->sec + treq->secs) ) {
	    block = (int) (sector/disk->sectors_per_block);
	    // DPRINTF("prsv: read_block() at block=%"PRIu64"", block);
	    if (read_block(disk, buf + (read_blocks * (DEFAULT_SECTOR_SIZE * disk->sectors_per_block)), block) == -1) {
	      DPRINTF("Failed to read_block at pd_read (NOT per block)");
	      return -1;
	    }
	    // point next sector if we have to read next block
	    sector = (block + 1) * disk->sectors_per_block;
	    read_blocks++;
	  }
	  memcpy(treq->buf, buf + ( (treq->sec % disk->sectors_per_block) * DEFAULT_SECTOR_SIZE), treq->secs * DEFAULT_SECTOR_SIZE);
	  //print_io(treq->buf, "read(p/non-b)", treq->sec, treq->secs, block, 0);
	  
	  return 0;
        }
}


int pd_write(struct preservation_disk *disk, td_request_t *treq) {
        size_t i, j, k,l;
	char buf[sizeof(struct entry_header) + DEFAULT_BLOCK_SIZE]={};
        struct entry_header header;
        size_t block_size = disk->header->block_size;
	uint64_t sector;
	uint64_t block;
	int remain_sectors;
	int current_update_sectors;
	size_t data_size;

        clock_gettime(CLOCK_REALTIME, &header.ts);

	// treq->sec から treq->secs 分のセクタを書き出す
	// 0  1  2  3  4  5  6  7
	// 8  9 10 11 12 13 14 15
	sector = treq->sec;
	remain_sectors = treq->secs;

	while ( sector < (treq->sec + treq->secs) ) {
	  current_update_sectors = 0;
	  block = (int) (sector/disk->sectors_per_block);

	  // このブロックの最新のデータを buf へ読み込む (1ブロックで末尾はゼロで埋められる）
	  if (read_latest_block(disk, buf + sizeof(struct entry_header), block) == -1) {
	   	DPRINTF("Failed to read_latest_block before updating index");
	    	return -1;
	  }
	  // buf の書き込み要求のあった該当セクタの部分だけ更新する
	  if( (disk->sectors_per_block - (sector % disk->sectors_per_block)) < remain_sectors ) {
	    current_update_sectors = (disk->sectors_per_block - (sector % disk->sectors_per_block));
	    remain_sectors -= current_update_sectors;
	  } else {
	    current_update_sectors = remain_sectors;
	    remain_sectors = 0;
	  }
	  memcpy(buf + sizeof(struct entry_header) + (sector % disk->sectors_per_block) * DEFAULT_SECTOR_SIZE,
		 treq->buf +  (treq->secs - remain_sectors - current_update_sectors) * DEFAULT_SECTOR_SIZE,
		 current_update_sectors * DEFAULT_SECTOR_SIZE);
	  
	  // 末尾の０を除いた実質的なサイズを調べる
	  data_size = get_actual_data_size(disk, buf + sizeof(struct entry_header));

	  // ヘッダの構造体をセットする（書き込みは後で）
	  header.next = disk->index_table[block];
	  header.data_size = data_size;
	  memcpy(buf, &header, sizeof(struct entry_header));

	  // デバッグ表示
	  // (1) for comparing with output of block-aio.c
	  /* print_io( buf + sizeof(struct entry_header) + (sector % disk->sectors_per_block) * DEFAULT_SECTOR_SIZE,
	     "write", sector, current_update_sectors, block, current_update_sectors * DEFAULT_SECTOR_SIZE);
	  */	  
	  
	  // データがすべて 0 で、かつ今までに一度も書き込まれていない場合、書き込みを無視
	  if (data_size == 0 && disk->index_table[block] == 0) {
	    // 次のセクターを指すように変更
	    sector = (block + 1) * disk->sectors_per_block;
	    continue;
	  }
	  
	  // (2) for comparing with the index of preservation.c
	  //print_header(&header);
	  //print_io( buf + sizeof(struct entry_header), "write", treq->sec, treq->secs, block, data_size);
	  
	  // 次のセクターを指すように変更
	  sector = (block + 1) * disk->sectors_per_block;
	  
	  /* 該当ブロックのエントリを作成して書き込む */
	  disk->index_table[block] = bio_write(&disk->bio, buf, sizeof(struct entry_header) + data_size);
	  
	}
		
        return 0;
}
