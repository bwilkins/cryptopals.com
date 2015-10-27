require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'

$cipher_key = nil
def ECB_encrypt_rand_key(input_str)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 0
  $cipher_key ||= cipher.random_key
  cipher.key = $cipher_key
  cipher.update(input_str) + cipher.final
end

def ECB_encrypt(input)
  output = ""

  input.bytes.each_slice(16).map do |byte_slice|
    byte_slice0 = pad_block_bytea(byte_slice, 16)
    output << ECB_encrypt_rand_key(bytea_to_str(byte_slice0))
  end
  output
end

def CBC_encrypt(input)
  _iv = random_bytea(16)
  output = ""

  input.bytes.each_slice(16).map do |byte_slice|
    byte_slice0 = pad_block_bytea(byte_slice, 16)
    byte_slice1 = xor_bytea_bytea(byte_slice0, _iv)
    output << (_iv = ECB_encrypt_rand_key(bytea_to_str(byte_slice1)))
    _iv = _iv.bytes
  end
  output
end

def encrypt(input_str)
  plain_text = random_pad + input_str + random_pad
  case [:ecb, :cbc].sample
  when :ecb
    puts "It should be ECB!"
    ECB_encrypt(plain_text)
  else
    puts "It should be CBC!"
    CBC_encrypt(plain_text)
  end
end

INPUT = File.read(File.expand_path('../11.txt', __FILE__))

encrypted = encrypt(INPUT)

puts "Which mode do I detect?: #{detect_AES_mode(encrypted.bytes)}"
