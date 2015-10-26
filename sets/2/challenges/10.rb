#!/usr/bin/env ruby

require 'base64'
require 'openssl'

KEY="YELLOW SUBMARINE"

def pad_block_bytea(block, block_length)
  if block.length >=block_length
    return block
  end

  length_to_pad = block_length - block.length
  length_to_pad.times do
    block << length_to_pad
  end

  block
end


def xor_bytea_bytea(bytea1, bytea2)
  return [] if bytea1.size != bytea2.size

  Array.new.tap do |a|
    bytea1.each_with_index do |byte, i|
      a << (byte ^ bytea2[i])
    end
  end
end

def bytea_to_str(bytea)
  bytea.map(&:chr).join
end

def ECB_encrypt(input, key)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 0
  cipher.key = key
  foo = cipher.update(input)
  foo << cipher.final
  foo
end

def ECB_decrypt(input, key)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.decrypt
  cipher.padding = 0
  cipher.key = key
  foo = cipher.update(input)
  foo << cipher.final
  foo
end

def CBC_decrypt(input, key, iv)
  _iv = iv.dup.bytes
  output = ""

  input.bytes.each_slice(16).map do |byte_slice|
    x = ECB_decrypt(bytea_to_str(byte_slice), key)
    output << bytea_to_str(xor_bytea_bytea(x.bytes, _iv))
    _iv = byte_slice
  end

  output
end

def CBC_encrypt(input, key, iv)
  _iv = iv.dup
  output = ""

  input.bytes.each_slice(16).map do |byte_slice|
    byte_slice = pad_block_bytea(byte_slice, 16)
    byte_slice = xor_bytea_bytea(byte_slice, _iv.bytes)
    output << _iv = ECB_encrypt(bytea_to_str(byte_slice), key)
  end
  output
end

file_contents = File.read(File.expand_path('../10.txt', __FILE__)).chomp
data = Base64.decode64(file_contents)

puts "Decryption Output:"
output = CBC_decrypt(data, KEY, (0x0.chr * 16))
puts output

test = CBC_encrypt(output, KEY, (0x0.chr * 16))

puts "Does Encrypt give the same data?: #{test == data}"

puts Base64.encode64(test)
