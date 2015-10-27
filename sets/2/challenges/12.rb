require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'


$cipher_key = nil
def encrypt(input_str)
  plain_text = input_str + Base64.decode64(
  <<-SURPRISE
Um9sbGluJyBpbiBteSA1LjAKV2l0aCBteSByYWctdG9wIGRvd24gc28gbXkg
aGFpciBjYW4gYmxvdwpUaGUgZ2lybGllcyBvbiBzdGFuZGJ5IHdhdmluZyBq
dXN0IHRvIHNheSBoaQpEaWQgeW91IHN0b3A/IE5vLCBJIGp1c3QgZHJvdmUg
YnkK
  SURPRISE
  )
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 0
  cipher.key = $cipher_key ||= random_str(16)
  String.new.tap do |cipher_text|
    plain_text.bytes.each_slice(16) do |slice|
      padded = pad_block_bytea(slice,16)
      padded_str = bytea_to_str(padded)
      cipher_text << cipher.update(padded_str)
    end
    cipher_text << cipher.final
  end
end

def discover_ECB_mode(&block)
  discovery_block = 'A'*1024
  encrypted = block.call(discovery_block)
  detect_ECB_mode(encrypted.bytes)
end

def discover_block_size(&block)
  i = 0
  encrypted = ''
  until detect_ECB_mode(encrypted.bytes)
    i+=1
    encrypted = block.call('A'*(i*2))
  end
  i
end

def discover_secret_length(&block)
  i=0
  base_length = block.call('').length
  test_length = block.call('A'*i).length
  while test_length == base_length
    i+=1
    test_length = block.call('A'*i).length
  end
  base_length - (i-1)
end

ecb = discover_ECB_mode {|input| encrypt(input)}
block_size = discover_block_size {|input| encrypt(input)}
secret_length = discover_secret_length{|input| encrypt(input)}
secret_remainder = secret_length % 16
secret_only_pad_size = 16 - secret_remainder

puts "In ECB mode?: #{ecb}"
puts "What is the block size?: #{block_size}"
puts "What is the secret length?: #{secret_length}"
puts "What is the secret-only pad size?: #{secret_only_pad_size}"

discovered_bytes = ""
greater_dict = Hash.new
block_size.times do |size|
  pad_length = block_size - size - 1
  padding = 'A'*pad_length
  dictionary = (0x0..0xFF).inject({}) do |dict, byte|
    input = padding + discovered_bytes + byte.chr
    cipher_text = encrypt(input)[0,16]
    greater_dict[cipher_text] = input
    dict.merge(cipher_text => byte.chr)
  end
  encrypted = encrypt(padding)[0,16]
  discovered_bytes << dictionary[encrypted]
end



discovered_tail = ""
mandatory_pad = 'A'*(secret_only_pad_size)
(block_size-1).times do |size|
  dictionary = (0x0..0xFF).inject({}) do |dict, byte|
    input = pad_block(byte.chr + discovered_tail, block_size)
    encrypted = encrypt(input + 'A' * size + mandatory_pad)
    head_cipher_text = encrypted[0, 16]
    greater_dict[head_cipher_text] = input
    dict.merge(head_cipher_text => byte.chr)
  end

  encrypted = bytea_to_str(encrypt('A'*(secret_only_pad_size+size+1)).bytes.last(16))
  begin
    discovered_tail = dictionary[encrypted] + discovered_tail
  rescue
    require 'pry'
    binding.pry
    nil
  end
end

puts "Discovered at the head:"
puts discovered_bytes
puts
puts "Discovered at the tail:"
puts discovered_tail
puts

puts "Final:"
encrypted = encrypt(discovered_bytes)
bytea_to_hexstr(encrypted.bytes).chars.each_slice(32) do |slice|
  puts slice.join
end


#require 'pry'
#binding.pry

exit
