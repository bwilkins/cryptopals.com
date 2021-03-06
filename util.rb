require 'base64'
require 'forwardable'
require 'openssl'

RAND_BYTES = (0x0..0xFF).to_a
PAD_LEN = (5..10).to_a

class ByteArray
  extend Forwardable
  include Comparable

  def initialize(input=[])
    @bytes = input # Assumed to be an array of bytes already
  end

  def_delegators :@bytes, :last, :[], :[]=, :<<, :length, :size

  def <=>(other)
    other <=> @bytes
  end

  def self.from_string(s)
    new(s.bytes)
  end

  def self.from_hexstr(s)
    from_string([s].pack('H*'))
  end

  def self.blank(size=16)
    new([0]*size)
  end

  def dup
    self.class.new(@bytes.dup)
  end

  def to_s
    @bytes.map(&:chr).join
  end

  def to_str
    @bytes.map(&:chr).join
  end

  def to_hexstr
    @bytes.map{|b|"%02x"%b}.join
  end

  def each_slice(count)
    @bytes.each_slice(count).map do |slice|
      self.class.new(slice)
    end.each do |slice|
      yield slice if block_given?
    end
  end

  def pad(pad_size)
    dup.tap do |dup|
      dup.pad!(pad_size)
    end
  end

  def pad!(pad_size)
    size_diff = pad_size - length
    @bytes += ([size_diff] * size_diff) if size_diff > 0
  end

  def has_valid_padding?
    last != 0 &&
    @bytes[-last, last] == [last] * last
  end

  def xor!(against)
    if against.is_a?(self.class)
      xor_bytea!(against)
    elsif against.is_a?(String)
      xor_bytea!(ByteArray.from_string(against))
    else
      xor_byte!(against)
    end
  end

  def xor(against)
    self.dup.tap do |d|
      d.xor!(against)
    end
  end

  def not
    self.dup.tap(&:not!)
  end

  def not!
    @bytes.map!(&:~)
  end

  def and(other)
    self.dup.tap do |b|
      b.and!(other)
    end
  end

  def and!(other)
    if size != other.size
      if other.size == 1
        @bytes.each_with_index do |byte, i|
          self[i] = byte & other[0]
        end
      end
      return nil
    end
    @bytes.each_with_index do |byte, i|
      self[i] = byte & other[i]
    end
  end

  def neg
    self.dup.tap(&:neg!)
  end

  def neg!
    @bytes.map!{|byte| -byte}
  end

  private

  def xor_bytea!(against)
    if self.size != against.size
      if against.size == 1
        xor_byte!(against[0])
      end
      return nil
    end

    @bytes.each_with_index do |byte, i|
      self[i] = (byte ^ against[i])
    end
  end

  def xor_byte!(against)
    @bytes.each_with_index do |byte, i|
      self[i] = (byte ^ against)
    end
  end
end

def pad_block(block, block_length)
  return block if block.length >=block_length
  length_to_pad = block_length - block.length
  block + length_to_pad.chr*length_to_pad
end

def pad_block_bytea(block, block_length)
  return block if block.length >=block_length
  length_to_pad = block_length - block.length
  block + ([length_to_pad] * length_to_pad)
end

def random_pad
  random_str(PAD_LEN.sample)
end

def random_str(len)
  random_bytea(len).map(&:chr).join
end

def random_bytea(len)
  pad = Array.new.tap do |pad|
    len.times do
      pad << RAND_BYTES.sample
    end
  end
end

def xor_bytea_byte(bytea, byte)
  bytea.map { |b| b ^ byte }
end

def xor_bytea_bytea(bytea1, bytea2)
  return [] if bytea1.size != bytea2.size

  Array.new.tap do |a|
    bytea1.each_with_index do |byte, i|
      a << (byte ^ bytea2[i])
    end
  end
end

def hexstr_to_bytea(hex_str)
  return ByteArray.new if (hex_str.size % 2) != 0
  ByteArray.from_string([hex_str].pack('H*'))
end

def bytea_to_hexstr(bytea)
  bytea.map{|b|"%02x"%b}.join
end

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

def detect_ECB_mode(line_bytea)
  slices = line_bytea.each_slice(16).to_a
  slices.length != slices.uniq{|s|s[0,s.length]}.length
end


def detect_AES_mode(line_bytea)
  slices = line_bytea.each_slice(16).to_a
  slices.length != slices.uniq{|s|s[0,s.length]}.length ? :ECB : :CBC
end

def discover_ECB_mode(&block)
  discovery_block = 'A'*1024
  encrypted = block.call(discovery_block)
  detect_ECB_mode(ByteArray.from_string(encrypted))
end

def discover_block_size(&block)
  test_block_1 = block.call('A').bytes
  test_block_2 = block.call('B').bytes
  while test_block_1.first == test_block_2.first
    test_block_1.shift
    test_block_2.shift
  end
  while test_block_1.last == test_block_2.last
    test_block_1.pop
    test_block_2.pop
  end
  test_block_1.length
end

def discover_PKCS7_pad_length(&block)
  i=0
  base_length = block.call('').length
  test_length = block.call('A'*i).length
  while test_length == base_length
    i+=1
    test_length = block.call('A'*i).length
  end
  i-1
end

def discover_prefix_length(&block)
  uncontrolled_blocks = discover_first_controlled_block(&block)
  block_size = discover_block_size(&block)
  bytes_controlled = discover_first_block_controlled_byte_count(&block)
  bytes_not_controlled = block_size - bytes_controlled
  bytes_not_controlled + uncontrolled_blocks * block_size
end

def discover_secret_length(&block)
  bytes_not_controlled = discover_prefix_length(&block)
  base_length = block.call('').length
  base_length - bytes_not_controlled - discover_PKCS7_pad_length(&block)
end

def discover_first_controlled_block(&block)
  blocks = 0
  block_size = discover_block_size(&block)
  found = false
  base = block.call('')
  test = block.call('A')
  first = ByteArray.from_string(base).each_slice(block_size)
  second = ByteArray.from_string(test).each_slice(block_size)
  while not found
    first.shift == second.shift ? blocks += 1 : found = true
  end
  blocks
end

# Knowing the first block we control, we also need to know
# how many bytes we don't have control of (or how many bytes we do) in that first block
def discover_first_block_controlled_byte_count(&block)
  byte_count = 1
  found = false

  blocks = discover_first_controlled_block(&block)
  block_size = discover_block_size(&block)
  last_block = ByteArray.from_string(block.call('A'*0)).each_slice(block_size)[blocks]

  while not found
    check_block = ByteArray.from_string(block.call('A'*byte_count)).each_slice(block_size)[blocks]
    check_block != last_block ? byte_count += 1 : found = true
    last_block = check_block
  end

  byte_count - 1
end

def has_valid_padding?(str)
  ByteArray.from_string(str).has_valid_padding?
end

def check_padding!(str)
  raise ArgumentError unless has_valid_padding?(str)
end

def ECB_encrypt(input_str, key)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 0
  cipher.key = key
  cipher.update(input_str) + cipher.final
end

def ECB_decrypt(input_str, key)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.decrypt
  cipher.padding = 0
  cipher.key = key
  cipher.update(input_str) + cipher.final
end

def ECB_encrypt_rand_key(input_str)
  $cipher_key ||= random_str(16)
  ECB_encrypt(input_str, $cipher_key)
end

def ECB_decrypt_rand_key(input_str)
  $cipher_key ||= random_str(16)
  ECB_decrypt(input_str)
end

def CBC_encrypt(input, key, iv)
  input = ByteArray.from_string(input)
  _iv = iv
  output = ""

  input.each_slice(16).map do |byte_slice|
    byte_slice.pad!(16)
    byte_slice.xor!(_iv)
    output << (_iv = ECB_encrypt(byte_slice.to_s, key))
    _iv = ByteArray.from_string(_iv)
  end
  output
end

def CBC_decrypt(input, key, iv)
  input = ByteArray.from_string(input)
  _iv = iv
  output = ""

  input.each_slice(16).map do |byte_slice|
    byte_slice0 = ByteArray.from_string(ECB_decrypt(byte_slice.to_s, key))
    output << byte_slice0.xor(_iv).to_s
    _iv = byte_slice
  end
  output
end

def CBC_encrypt_rand_key(input, iv)
  $cipher_key ||= random_str(16)
  CBC_encrypt(input, $cipher_key, iv)
end

def CBC_decrypt_rand_key(input, iv)
  $cipher_key ||= random_str(16)
  CBC_decrypt(input, $cipher_key, iv)
end

def CTR_crypt(input, key, nonce)
  String.new.tap do |plain_text|
    slice_count = 0
    ByteArray.from_string(input).each_slice(16) do |slice|
      plain_text << slice.xor(CTR_keystream(key, nonce, slice_count*16)[0, slice.length]).to_s
      slice_count += 1
    end
  end
end

def CTR_keystream(key, nonce, byte_count)
  ECB_encrypt([nonce, byte_count/16].pack('q<q<'), key)
end
