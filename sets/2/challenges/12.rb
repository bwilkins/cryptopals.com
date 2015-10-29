require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'


def encrypt(input_str)
  plain_text = ByteArray.from_string(input_str + Base64.decode64(
    <<-SURPRISE
Um9sbGluJyBpbiBteSA1LjAKV2l0aCBteSByYWctdG9wIGRvd24gc28gbXkg
aGFpciBjYW4gYmxvdwpUaGUgZ2lybGllcyBvbiBzdGFuZGJ5IHdhdmluZyBq
dXN0IHRvIHNheSBoaQpEaWQgeW91IHN0b3A/IE5vLCBJIGp1c3QgZHJvdmUg
YnkK
    SURPRISE
  ))
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 0
  cipher.key = $cipher_key ||= random_str(16)
  String.new.tap do |cipher_text|
    plain_text.each_slice(16) do |slice|
      cipher_text << cipher.update(slice.pad(16).to_s)
    end
    cipher_text << cipher.final
  end
end

ecb = discover_ECB_mode {|input| encrypt(input)}
block_size = discover_block_size {|input| encrypt(input)}
secret_length = discover_secret_length{|input| encrypt(input)}
secret_remainder = secret_length % block_size
secret_only_pad_size = block_size - secret_remainder

puts "In ECB mode?: #{ecb}"
puts "What is the block size?: #{block_size}"
puts "What is the secret length?: #{secret_length}"
puts "What is the secret-only pad size?: #{secret_only_pad_size}"

def padding_oracle_attack(&block)
  discovered_bytes = ""
  secret_length = discover_secret_length(&block)
  block_size = discover_block_size(&block)
  while discovered_bytes.length < secret_length do
    block_shift = discovered_bytes.length / block_size
    block_shift_pad_length = block_shift * block_size
    block_size.times do |size|
      break if discovered_bytes.length >= secret_length
      pad_length = block_shift_pad_length +block_size - discovered_bytes.length - 1
      padding = 'A'*pad_length
      dictionary = (0x0..0xFF).inject({}) do |dict, byte|
        input = padding + discovered_bytes + byte.chr
        cipher_text = block.call(input)[block_shift_pad_length,block_size]
        dict.merge(cipher_text => byte.chr)
      end
      encrypted = block.call(padding)[block_shift_pad_length,block_size]
      byte = dictionary[encrypted]
      discovered_bytes << byte
    end
  end
  return discovered_bytes
end



puts
puts "Decrypted secret:"
puts padding_oracle_attack {|input| encrypt(input)}
puts

exit
