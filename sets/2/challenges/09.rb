#!/usr/bin/env ruby

INPUT="YELLOW SUBMARINE"
EXPECTED_OUTPUT="YELLOW SUBMARINE\x04\x04\x04\x04"

def pad_block(block, block_length)
  if block.length >=block_length
    return block
  end

  length_to_pad = block_length - block.length
  length_to_pad.times do
    block << length_to_pad.chr
  end

  block
end

puts "Input: #{INPUT}"
puts "Output meets expectation: #{pad_block(INPUT, 20) == EXPECTED_OUTPUT}"
