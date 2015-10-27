#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

INPUT="YELLOW SUBMARINE"
EXPECTED_OUTPUT="YELLOW SUBMARINE\x04\x04\x04\x04"


puts "Input: #{INPUT}"
puts "Output meets expectation: #{pad_block(INPUT, 20) == EXPECTED_OUTPUT}"
