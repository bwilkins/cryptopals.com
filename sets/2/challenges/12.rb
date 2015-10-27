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
while discovered_bytes.length < secret_length do
  block_shift = discovered_bytes.length / block_size
  block_shift_pad_length = block_shift * block_size
  block_size.times do |size|
    break if discovered_bytes.length >= secret_length
    pad_length = block_shift_pad_length +block_size - discovered_bytes.length - 1
    padding = 'A'*pad_length
    dictionary = (0x0..0xFF).inject({}) do |dict, byte|
      input = padding + discovered_bytes + byte.chr
      cipher_text = encrypt(input)[block_shift_pad_length,block_size]
      dict.merge(cipher_text => byte.chr)
    end
    encrypted = encrypt(padding)[block_shift_pad_length,block_size]
    byte = dictionary[encrypted]
    discovered_bytes << byte
  end
end



puts
puts "Decrypted secret:"
puts discovered_bytes
puts

exit
