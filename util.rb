require 'base64'

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
