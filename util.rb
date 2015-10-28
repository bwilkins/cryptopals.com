require 'base64'
require 'forwardable'

RAND_BYTES = (0x0..0xFF).to_a
PAD_LEN = (5..10).to_a

class ByteArray
  extend Forwardable

  def initialize(input=[])
    @bytes = input # Assumed to be an array of bytes already
  end
  def_delegators :@bytes, :[], :[]=, :<<, :length, :size

  def self.from_string(s)
    new(s.bytes)
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


  def each_slice(count)
    @bytes.each_slice.map do |slice|
      self.class.new(slice)
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


  def xor(against)
    if against.is_a?(self.class)
      #
    end
  end

  private

  def xor_bytea(against)
    return ByteArray.new if self.size != against.size

    self.class.new.tap do |a|
      @bytes.each_with_index do |byte, i|
        a << (byte ^ bytea2[i])
      end
    end
  end

  def xor_byte(against)
    self.class.new.tap do |a|
      @bytes.each do |byte|
        a << (byte ^ against)
      end
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

def str_to_bytea(str)
  str.bytes
end

def bytea_to_str(bytea)
  bytea.map(&:chr).join
end


def hexstr_to_bytea(hex_str)
  return [] if (hex_str.size % 2) != 0
  hex_str.chars.each_slice(2).map do |high, low|
    "#{high}#{low}".hex
  end
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
  slices.length != slices.uniq.length
end


def detect_AES_mode(line_bytea)
  slices = line_bytea.each_slice(16).to_a
  slices.length != slices.uniq.length ? :ECB : :CBC
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

