#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# mkimage.rb file_to_be_created disk_size_in_byte block_size_in_byte

file = ARGV[0]
# disk size in byte
disk_size = Integer(ARGV[1])
block_size = Integer(ARGV[2])

data = [
  #disk size in byte
  disk_size,
  # block size in byte
  block_size,
  # next offset that begins first record of writes
  # the offset set to the location after the index of the records
  512 + (disk_size / block_size * 8 + 511) / 512 * 512,
]
open(file, 'w') do |f|
  f << data.pack('QQQ')
end
