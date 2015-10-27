#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

INPUT1 = "1c0111001f010100061a024b53535009181c"
INPUT2 = "686974207468652062756c6c277320657965"
EXPECTED_OUTPUT = "746865206b696420646f6e277420706c6179"

def challenge2(input1, input2)
  b1 = hexstr_to_bytea(input1)
  b2 = hexstr_to_bytea(input2)
  ob = xor_bytea_bytea(b1, b2)
  bytea_to_hexstr(ob)
end

puts "Input1: #{INPUT1}"
puts "Input2: #{INPUT2}"
puts "Output: #{challenge2(INPUT1, INPUT2)}"
puts "Output matches expected? #{ challenge2(INPUT1, INPUT2) == EXPECTED_OUTPUT }"
