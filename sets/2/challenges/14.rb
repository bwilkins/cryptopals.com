require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'

def random_bumper
  $random_bumper ||= random_str((1..100).to_a.sample)
end

def encrypt(input_str)

  plain_text = ByteArray.from_string(random_bumper + input_str + Base64.decode64(
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
secret_only_pad_size = discover_PKCS7_pad_length{|input| encrypt(input)}

puts "In ECB mode?: #{ecb}"
puts "What is the block size?: #{block_size}"
puts "What is the secret length?: #{secret_length}"
puts "What is the secret-only pad size?: #{secret_only_pad_size}"

def padding_oracle_attack(&block)
  discovered_bytes = ""
  secret_length = discover_secret_length(&block)
  block_size = discover_block_size(&block)
  number_of_uncontrolled_blocks = discover_first_controlled_block(&block)
  bytes_controlled = discover_first_block_controlled_byte_count(&block)
  bytes_not_controlled = block_size - bytes_controlled
  uncontrolled_block_shift = number_of_uncontrolled_blocks * block_size


  while discovered_bytes.length < secret_length do
    block_shift = (bytes_not_controlled + discovered_bytes.length) / block_size
    block_shift_pad_length = block_shift * block_size
    block_size.times do |size|
      pad_length = block_shift_pad_length + block_size - (bytes_not_controlled + discovered_bytes.length) - 1
      break if pad_length < 0
      break if discovered_bytes.length >= secret_length
      padding = 'A'*pad_length
      dictionary = (0x0..0xFF).inject({}) do |dict, byte|
        input = padding + discovered_bytes + byte.chr
        cipher_text = block.call(input)[uncontrolled_block_shift + block_shift_pad_length,block_size]
        dict.merge(cipher_text => byte.chr)
      end
      encrypted = block.call(padding)[uncontrolled_block_shift + block_shift_pad_length,block_size]
      byte = dictionary[encrypted]
      begin
        discovered_bytes << byte
      rescue
        puts "Error occured! but here's what I got so far:"
        discovered_bytes.bytes.each do |byte|
          puts "#{byte}(#{byte.chr})"
        end
        exit
      end
    end
  end
  return discovered_bytes
end

puts
puts "Decrypted secret:"
puts padding_oracle_attack {|input| encrypt(input)}
puts

exit
