#!/usr/bin/env ruby

require 'base64'

INPUT1 = "1c0111001f010100061a024b53535009181c"
INPUT2 = "686974207468652062756c6c277320657965"
EXPECTED_OUTPUT = "746865206b696420646f6e277420706c6179"

def hexstr_to_bytea(hex_str)
  return [] if (hex_str.size % 2) != 0
  hex_str.chars.each_slice(2).map do |high, low|
    "#{high}#{low}".hex
  end
end

def bytea_to_str(bytea)
  bytea.map(&:chr).join
end

def xor_bytea_bytea(bytea1, bytea2)
  return [] if bytea1.size != bytea2.size

  Array.new.tap do |a|
    bytea1.each_with_index do |byte, i|
      a << (byte ^ bytea2[i])
    end
  end
end

def bytea_to_hexstr(bytea)
  bytea.map{|b|"%02x"%b}.join
end

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
