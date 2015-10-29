#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

INPUT = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d"
EXPECTED_OUTPUT = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t"

def hex_to_base64(hex_str)
  bytea = hexstr_to_bytea(hex_str)
  Base64.encode64(bytea.to_s).gsub(/\W/,'')
end

puts "Input: #{INPUT}"
puts "Output: #{hex_to_base64(INPUT)}"
puts "Output matches expected? #{ hex_to_base64(INPUT) == EXPECTED_OUTPUT }"
