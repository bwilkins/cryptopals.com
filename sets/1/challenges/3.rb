#!/usr/bin/env ruby

require 'base64'

INPUT = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736"
RANKING = "ETAOIN SHRDLU"

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

def xor_bytea_byte(bytea, byte)
  bytea.map { |b| b ^ byte }
end

def bytea_to_hexstr(bytea)
  bytea.map{|b|"%2x"%b}.join
end

def rank_permutation(permutation)
  RANKING.chars.each_with_index.inject(0) do |sum, (char, index)|
    weight = RANKING.size - index
    sum += weight * permutation.count(char)
  end
end

def find_most_likely_decoded_sequence(input1)
  b1 = hexstr_to_bytea(input1)
  permutations = (0..255).map do |byte|
    bytea_to_str(xor_bytea_byte(b1, byte)).upcase
  end

  ranked = permutations.each_with_index.inject({}) do |set, (perm, index)|
    set.tap do |s|
    s[rank_permutation(perm)] = {byte: index,permutation: perm}
    end
  end

  [ranked.keys.max, ranked[ranked.keys.max]]
end

ranking, permutation = find_most_likely_decoded_sequence(INPUT)

puts "Input1: #{INPUT}"
puts "Most likely permutation: #{permutation[:permutation]}"
puts "XOR byte: #{"0x%2x"%permutation[:byte]} (\"#{permutation[:byte].chr}\")"
