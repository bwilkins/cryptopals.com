#!/usr/bin/env ruby

require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'

KEY="YELLOW SUBMARINE"

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
  _iv = ByteArray.from_string(iv)
  input = ByteArray.from_string(input)
  output = ""

  input.each_slice(16).map do |byte_slice|
    x = ECB_decrypt(byte_slice.to_s, key)
    intermediate = ByteArray.from_string(x)
    output << intermediate.xor(_iv).to_s
    _iv = byte_slice
  end

  output
end

def CBC_encrypt(input, key, iv)
  _iv = ByteArray.from_string(iv)
  input = ByteArray.from_string(input)
  output = ""

  input.each_slice(16).map do |byte_slice|
    byte_slice.pad!(16)
    byte_slice = byte_slice.xor(_iv)
    output << _iv = ECB_encrypt(byte_slice.to_s, key)
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
