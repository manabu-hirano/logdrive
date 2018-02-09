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

/*
 * Copyright (c) 2007, XenSource Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of XenSource Inc. nor the names of its contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
#include <glob.h>
#include <limits.h>

#include "blk.h"
#include "tapdisk.h"
#include "tapdisk-driver.h"
#include "tapdisk-interface.h"

#include "preservation.h"

struct tdtimetravel_state;

struct tdtimetravel_state {
        td_driver_t              *driver;

        struct preservation_disk  disk;
};

/* Open the disk file and initialize aio state. */
int tdtimetravel_open(td_driver_t *driver, const char *name, td_flag_t flags)
{
        int ret;
        struct tdtimetravel_state *prv;
        struct timespec ts;
        char *colon;
        char *name_time;

        ret = 0;
        prv = (struct tdtimetravel_state *)driver->data;

        name_time = calloc(strlen(name), sizeof(char));
        if (!name_time) {
                goto fail;
        }
        strcpy(name_time, name);
        colon = strchr(name_time, ':');
        *colon = '\0';

        DPRINTF("block-timetravel open('%s')", name);

        memset(prv, 0, sizeof(struct tdtimetravel_state));

        ts.tv_sec = strtoull(colon + 1, NULL, 10);
        ts.tv_nsec = 0;

        ret = pd_initialize_read_only(&prv->disk, name_time, &ts);
        if (ret == -1) {
                goto fail;
        }
        pd_set_driver_info(&prv->disk, &driver->info);

fail:
        free(name_time);

        return ret;
}

void tdtimetravel_queue_read(td_driver_t *driver, td_request_t treq)
{
        struct tdtimetravel_state *prv = (struct tdtimetravel_state *)driver->data;

        if (pd_read(&prv->disk, &treq) == -1) {
                td_complete_request(treq, -EBUSY);
                return;
        }
        td_complete_request(treq, 0);
}

void tdtimetravel_queue_write(td_driver_t *driver, td_request_t treq)
{
        /* Always fail (read-only) */
        td_complete_request(treq, -EBUSY);
}

int tdtimetravel_close(td_driver_t *driver)
{
        struct tdtimetravel_state *prv = (struct tdtimetravel_state *)driver->data;

        pd_finalize(&prv->disk);
        return 0;
}

int tdtimetravel_get_parent_id(td_driver_t *driver, td_disk_id_t *id)
{
        return TD_NO_PARENT;
}

int tdtimetravel_validate_parent(td_driver_t *driver,
                          td_driver_t *pdriver, td_flag_t flags)
{
        return -EINVAL;
}

struct tap_disk tapdisk_timetravel = {
        .disk_type          = "tapdisk_timetravel",
        .flags              = 0,
        .private_data_size  = sizeof(struct tdtimetravel_state),
        .td_open            = tdtimetravel_open,
        .td_close           = tdtimetravel_close,
        .td_queue_read      = tdtimetravel_queue_read,
        .td_queue_write     = tdtimetravel_queue_write,
        .td_get_parent_id   = tdtimetravel_get_parent_id,
        .td_validate_parent = tdtimetravel_validate_parent,
        .td_debug           = NULL,
};
