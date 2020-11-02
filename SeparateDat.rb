# SeparateDat.rb
#
# Author: Rea
#
# Separates Zanki Zero .dat files into individual decompressed .bin files.
# Licensed under the MIT license. See LICENSE at the root of the repository
# for more information.

# The path to all of Zanki Zero's .dat files.
ZANKI_ZERO_DAT_PATH = 'C:/Program Files (x86)/Steam/steamapps/common/ZankiZero/app'
# The ALLZ file identifier sequence.
ALLZ_FILE_IDENTIFIER = ['A', 'L', 'L', 'Z'].pack('aaaa')

# The files contained in this have five unknown bytes before the first ALLZ
# header. Skip to 0x05.
UNKNOWN_FIVE_BYTES_BEFORE_ALLZ = [
  '023.dat'
]

# The files contained in this are not compressed. Don't do anything with them,
# just write them as-is.
NOT_COMPRESSED = [
  '03f.dat'
]

# The files contained in this start uncompressed, and then contain ALLZ files 
# later on. It's hacky, but since there's only one file that fits this bill
# (at least in the en-US PC version of Zanki Zero), just skip to 0x2433 for
# the first ALLZ header.
STARTS_UNCOMPRESSED = [
  '054.dat'
]

# The files contained in this start with two hashes. The first ALLZ file starts
# at 0x48 for these.
TWO_HASHES = [
  '01d.dat',
  '02e.dat',
  '05a.dat',
  '071.dat',
  '0a0.dat'
]

# A fun combination of UNKNOWN_FIVE_BYTES_BEFORE_ALLZ and TWO_HASHES. Skip to
# 0x4D for this.
TWO_HASHES_THEN_UNKNOWN_FIVE_BYTES_BEFORE_ALLZ = [
  '04a.dat'
]

# The files contained in this start with a hash, followed by 0x142 before the 
# first ALLZ header. Skip to 0x28 for this.
MAGIC_NUMBER_BEFORE_ALLZ = [
  '084.dat'
]

require 'fileutils'

# main
allz_locations = {}
file_index_counter = 0

Dir.foreach(ZANKI_ZERO_DAT_PATH) do |dat_name|
  next if dat_name == '.' or dat_name == '..'
  allz_locations[dat_name] = []
  File.open(File.join(ZANKI_ZERO_DAT_PATH, dat_name), 'rb') do |dat_file|
    # Handle all the bizarre cases in the constant declarations above.
    if UNKNOWN_FIVE_BYTES_BEFORE_ALLZ.include?(dat_name) then
      dat_file.seek(0x05, :SET)
    elsif NOT_COMPRESSED.include?(dat_name) then
      # TODO
      next
    elsif STARTS_UNCOMPRESSED.include?(dat_name) then
      dat_file.seek(0x2433, :SET)
    elsif TWO_HASHES.include?(dat_name) then
      dat_file.seek(0x48, :SET)
    elsif TWO_HASHES_THEN_UNKNOWN_FIVE_BYTES_BEFORE_ALLZ.include?(dat_name) then
      dat_file.seek(0x4D, :SET)
    elsif MAGIC_NUMBER_BEFORE_ALLZ.include?(dat_name) then
      dat_file.seek(0x28, :SET)
    # If none of those applied, then we can, mercifully, just do things normally.
    else
      first_four = dat_file.read(4)
      # Some files start with a hash, for unknown reasons at this time. If the first
      # four bytes aren't ALLZ, then we need to skip to 0x24. Otherwise, jump back to
      # the start.
      if first_four != ALLZ_FILE_IDENTIFIER then
        dat_file.seek(0x24, :SET)
      else
        dat_file.seek(0x00, :SET)
      end
    end
    # Now, we need to find ALLZ sections. This is a bit clunky, but necessary: we read
    # the file's contents four times, each with the sliding window offset by a different
    # length. This is done because ALLZ file starts aren't aligned, and can come at any
    # position.
    data = dat_file.read
    (0..4).each do |offset|
      position = offset
      while position < data.length do
        window = data[position..(position + 3)]
        if window == ALLZ_FILE_IDENTIFIER then
          allz_locations[dat_name].append(position)
        end
        position += 4
      end
    end
    allz_locations[dat_name] = allz_locations[dat_name].uniq.sort
    allz_locations[dat_name].length.times do |length_index|
      file_length = 0
      # Final files in archives can just go until the end of the array.
      if length_index == (allz_locations[dat_name].length - 1) then
        file_length = data.length - allz_locations[dat_name][length_index]
      # Everything else has to get their lengths by comparing their locations with the
      # next file's.
      else
        file_length = allz_locations[dat_name][length_index + 1] - allz_locations[dat_name][length_index]
      end
      # Fencepost!
      file_length -= 1
      # Now, grab the ALLZ file from the archive, and write it to disk.
      File.open('Temp.bin', 'wb') do |temp_output| 
        file_data = data[allz_locations[dat_name][length_index]..allz_locations[dat_name][length_index] + file_length]
        temp_output.write(file_data)
      end
      # Decompress the file, write it to the output directory, remove the temp file, 
      # and move on.
      `Tools/Aqualead_LZSS.exe Temp.bin Separated/#{file_index_counter.to_s.rjust(6, '0')}.bin`
      FileUtils.rm('Temp.bin')
      file_index_counter += 1
    end
  end
  puts "Finished extracting all files from #{dat_name}."
end