#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))

INPUT="Burning 'em, if you ain't quick and nimble
I go crazy when I hear a cymbal"
XOR_KEY='ICE'

EXPECTED_OUTPUT = '0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f'

class RepeatingXorKey
  def initialize(key)
    @key = key.bytes
  end

  def encrypt(bytea)
    bytea.map { |b| b ^ byte }
  end

  def byte
    b = @key.first
    @key.rotate!
    return b
  end
end

key = RepeatingXorKey.new(XOR_KEY)
output_bytea = key.encrypt(INPUT.bytes)
output = bytea_to_hexstr(output_bytea)


puts "Input: #{INPUT}"
puts
puts "Output: #{output}"
puts "Output matches expectation: #{output == EXPECTED_OUTPUT}"
