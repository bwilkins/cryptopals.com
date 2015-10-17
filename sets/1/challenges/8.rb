require 'base64'
require 'openssl'

def hexstr_to_bytea(hex_str)
  return [] if (hex_str.size % 2) != 0
  hex_str.chars.each_slice(2).map do |high, low|
    "#{high}#{low}".hex
  end
end

file_lines = File.read(File.expand_path('../8.txt', __FILE__)).chomp.split

file_lines.each_with_index do |line, index|
  data = hexstr_to_bytea(line)
  slices = data.each_slice(16).to_a
  if slices.length != slices.uniq.length
    puts index+1
  end
end

