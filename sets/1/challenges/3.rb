#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

INPUT = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736"
RANKING = "ETAOIN SHRDLU"

def rank_permutation(permutation)
  RANKING.chars.each_with_index.inject(0) do |sum, (char, index)|
    weight = RANKING.size - index
    sum += weight * permutation.count(char)
  end
end

def find_most_likely_decoded_sequence(input1)
  b1 = hexstr_to_bytea(input1)
  permutations = (0..255).map do |byte|
    b1.xor(byte).to_s.upcase
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
