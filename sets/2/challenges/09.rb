#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

INPUT="YELLOW SUBMARINE"
EXPECTED_OUTPUT="YELLOW SUBMARINE\x04\x04\x04\x04"

bytea = ByteArray.from_string(INPUT)

puts "Input: #{INPUT}"
puts "Output meets expectation: #{bytea.pad(20).to_s == EXPECTED_OUTPUT}"
