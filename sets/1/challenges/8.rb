require 'base64'
require 'openssl'

def hexstr_to_bytea(hex_str)
  return [] if (hex_str.size % 2) != 0
  hex_str.chars.each_slice(2).map do |high, low|
    "#{high}#{low}".hex
  end
end

def detect_ECB_mode(line_bytea)
  slices = line_bytea.each_slice(16).to_a
  slices.length != slices.uniq.length
end

file_lines = File.read(File.expand_path('../8.txt', __FILE__)).chomp.split

file_lines.each_with_index do |line, index|
  data = hexstr_to_bytea(line)
  if detect_ECB_mode(data)
    puts index+1
  end
end

