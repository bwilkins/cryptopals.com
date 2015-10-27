require 'base64'
require 'openssl'

def pad_block(block, block_length)
  if block.length >=block_length
    return block
  end

  length_to_pad = block_length - block.length
  length_to_pad.times do
    block << length_to_pad.chr
  end

  block
end

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

def detect_AES_mode(line_bytea)
  slices = line_bytea.each_slice(16).to_a
  slices.length != slices.uniq.length ? :ECB : :CBC
end

RAND_BYTES = (0x0..0xFF).to_a
PAD_LEN = (5..10).to_a
def random_pad
  random_bytea(PAD_LEN.sample).map(&:chr).join
end

def random_bytea(len)
  pad = Array.new.tap do |pad|
    len.times do
      pad << RAND_BYTES.sample
    end
  end
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
