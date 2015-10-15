#!/usr/bin/env ruby

require 'base64'

input_file = File.expand_path('../6.txt', __FILE__)
input = File.read(input_file)
b64decoded = Base64.decode64(input)
bytea = b64decoded.bytes

RANKING = "EOTHA 'SINRD LUYMW FGCBP KVJQXZ"

def hamming_distance(s1, s2)
  if s1.size != s2.size
    puts "sizeof #{s1} != sizeof #{s2}"
    return nil
  end

  s1.zip(s2).inject(0) do |sum, (c1, c2)|
    val = c1 ^ c2
    while (val != 0)
      sum += 1
      val &= val - 1
    end
    sum
  end
end

def xor_bytea_byte(bytea, byte)
  bytea.map { |b| b ^ byte }
end

def bytea_to_hexstr(bytea)
  bytea.map{|b|"%02x"%b}.join
end

def rank_permutation(permutation)
  RANKING.chars.each_with_index.inject(0) do |sum, (char, index)|
    weight = RANKING.size - index
    sum += weight * permutation.count(char)
  end
end

def bytea_to_str(bytea)
  bytea.map(&:chr).join
end

def find_most_likely_byte(b1)
  permutations = (0..255).map do |byte|
    bytea_to_str(xor_bytea_byte(b1, byte)).upcase
  end

  ranked = permutations.each_with_index.inject({}) do |set, (perm, index)|
    set.tap do |s|
    s[rank_permutation(perm)] = index
  end
  end

  ranked[ranked.keys.max]
end

class RepeatingXorKey
  def initialize(key)
    @key = key.bytes
  end

  def crypt(bytea)
    bytea.map { |b| b ^ byte }
  end

  def byte
    b = @key.first
    @key.rotate!
    return b
  end
end


keysize_options = (2..40).inject({}) do |memo, keysize|
  bytea1 = bytea[0, keysize]
  bytea2 = bytea[keysize, keysize]
  bytea3 = bytea[keysize*2, keysize]
  bytea4 = bytea[keysize*3, keysize]
  bytea5 = bytea[keysize*4, keysize]

  dist1 = hamming_distance(bytea1, bytea2)
  dist2 = hamming_distance(bytea2, bytea3)
  dist3 = hamming_distance(bytea3, bytea4)
  dist4 = hamming_distance(bytea4, bytea5)

  dist = [dist1, dist2, dist3, dist4].min
  norm = dist/keysize

  memo[norm] ||= Array.new
  memo[norm] << {keysize: keysize, distance: dist}

  memo
end

keysize_norms = keysize_options.keys.sort
perms = keysize_norms.take(3).flat_map do |norm|
  keysize_options[norm].map do |keysize:, distance:|

    blocks_of_keysize = bytea.each_slice(keysize).to_a
  blocks_of_keysize.pop
  columns = blocks_of_keysize.transpose

  key_bytea = columns.map do |c|
    find_most_likely_byte(c)
  end

  key = bytea_to_str(key_bytea)

  xor_key = RepeatingXorKey.new(key)
  {key: key, perm: bytea_to_str(xor_key.crypt(bytea))}
  end
end

ranked = perms.inject({}) do |set, perm|
  set.tap do |s|
    s[rank_permutation(perm[:perm])] = perm
  end
end

puts "Key: #{ranked[ranked.keys.max][:key]}"
puts ranked[ranked.keys.max][:perm]

