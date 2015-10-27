#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

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
    bytea_to_str(xor_bytea_byte(b1, byte)).upcase
  end

  ranked = permutations.each_with_index.inject({}) do |set, (perm, index)|
    set.tap do |s|
    s[rank_permutation(perm)] = {byte: index, permutation: perm}
  end
  end

  [ranked.keys.max, ranked[ranked.keys.max]]
end

def find_encoded_needle(list)
  ranked = list.inject({}) do |memo, item|
    memo.tap do |m|
      ranking, permutation = find_most_likely_decoded_sequence(item)
      m[ranking] = permutation.merge(original: item)
    end
  end

  highest_rank = ranked.keys.max

  [highest_rank, ranked[highest_rank]]
end

file_path = File.expand_path("../4.txt",__FILE__)
file_contents = File.readlines(file_path).map(&:strip)
rank, permutation = find_encoded_needle(file_contents)

puts "Most likely input line: #{permutation[:original]}"
puts "Output: #{permutation[:permutation]}"
puts "XOR byte: #{"0x%2x"%permutation[:byte]} (\"#{permutation[:byte].chr}\")"
