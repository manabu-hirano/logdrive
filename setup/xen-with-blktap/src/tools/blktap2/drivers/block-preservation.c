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

#include "blk.h"
#include "tapdisk.h"
#include "tapdisk-driver.h"
#include "tapdisk-interface.h"

#include "preservation.h"

#define DEBUG_IO

struct tdpreservation_state;

struct tdpreservation_state {
        td_driver_t              *driver;
        struct preservation_disk  disk;
};

/* Open the disk file and initialize aio state. */
int tdpreservation_open(td_driver_t *driver, const char *name, td_flag_t flags)
{
        int ret;
        struct tdpreservation_state *prv;

        ret = 0;
        prv = (struct tdpreservation_state *)driver->data;

        DPRINTF("block-preservation open('%s')", name);

        memset(prv, 0, sizeof(struct tdpreservation_state));

        ret = pd_initialize(&prv->disk, name);
        if (ret == -1) {
                goto fail;
        }
        pd_set_driver_info(&prv->disk, &driver->info);

fail:
        return ret;
}

void tdpreservation_queue_read(td_driver_t *driver, td_request_t treq)
{
        struct tdpreservation_state *prv = (struct tdpreservation_state *)driver->data;

        if (pd_read(&prv->disk, &treq) == -1) {
                td_complete_request(treq, -EBUSY);
                return;
        }
        td_complete_request(treq, 0);
}

void tdpreservation_queue_write(td_driver_t *driver, td_request_t treq)
{
        struct tdpreservation_state *prv = (struct tdpreservation_state *)driver->data;

        if (pd_write(&prv->disk, &treq) == -1) {
	        td_complete_request(treq, -EBUSY);
                return;
        }
        td_complete_request(treq, 0);
}

int tdpreservation_close(td_driver_t *driver)
{
        struct tdpreservation_state *prv = (struct tdpreservation_state *)driver->data;

        pd_finalize(&prv->disk);
        return 0;
}

int tdpreservation_get_parent_id(td_driver_t *driver, td_disk_id_t *id)
{
        return TD_NO_PARENT;
}

int tdpreservation_validate_parent(td_driver_t *driver,
                          td_driver_t *pdriver, td_flag_t flags)
{
        return -EINVAL;
}

struct tap_disk tapdisk_preservation = {
        .disk_type          = "tapdisk_preservation",
        .flags              = 0,
        .private_data_size  = sizeof(struct tdpreservation_state),
        .td_open            = tdpreservation_open,
        .td_close           = tdpreservation_close,
        .td_queue_read      = tdpreservation_queue_read,
        .td_queue_write     = tdpreservation_queue_write,
        .td_get_parent_id   = tdpreservation_get_parent_id,
        .td_validate_parent = tdpreservation_validate_parent,
        .td_debug           = NULL,
};
