require(File.expand_path('../../../../util.rb', __FILE__))

Snippets = File.open(File.expand_path('../17.txt', __FILE__)) do |file|
  file.read.chomp.split("\n").map do |line|
    Base64.decode64(line)
  end
end

def generate
  data = Snippets.sample
  iv = random_str(16)
  ciphertext = CBC_encrypt_rand_key(data, iv)
  [ciphertext, iv]
end

def check(input, iv)
  plaintext = CBC_decrypt_rand_key(input, iv)

  has_valid_padding?(plaintext)
end

class SingleBlockOracle
  def initialize(ciphertext, original_iv)
    @ciphertext = ciphertext
    @original_iv = original_iv
    @decipher_iv = ByteArray.blank
    @discovered_intermediate = ByteArray.blank
    @discovered_bytes = []
    @block_size = ciphertext.length
    @last_char = block_size - 1
    @char_select = block_size - 1
  end

  def decipher
    while char_select >= 0
      find_char
      self.intermediate_byte = potential_intermediate_byte
      self.char_select -= 1
    end

    return discovered_bytes
  end

  private
  attr_reader :ciphertext, :original_iv, :decipher_iv, :discovered_intermediate,
    :discovered_bytes, :block_size, :last_char
  attr_accessor :char_select

  def discovered_bytes
    discovered_intermediate.xor(original_iv)
  end

  def discovered_byte
    discovered_bytes[char_select]
  end

  def working_byte
    decipher_iv[char_select]
  end

  def working_byte=(val)
    decipher_iv[char_select] = val
  end

  def intermediate_byte
    discovered_intermediate[char_select]
  end

  def intermediate_byte=(val)
    discovered_intermediate[char_select] = val
  end

  def potential_intermediate_byte
    working_byte ^ pad
  end

  def potential_byte
    potential_intermediate_byte ^ original_iv[char_select]
  end

  def next_padding
    indices = (char_select+1..last_char).to_a
    indices.inject(ByteArray.blank) do |bytea, index|
      bytea.tap do |b|
        b[index] = pad
      end
    end
  end

  def find_char
    @decipher_iv = discovered_intermediate.xor(next_padding)
    found_char = false
    while (not found_char) && (working_byte < 0x100)
      found_char = begin
                     check(ciphertext.to_s, decipher_iv.to_s)
                   rescue
                     false
                   end
      next_byte unless found_char
    end
    found_char
  end

  def next_byte
      self.working_byte = working_byte + 1
  end

  def pad
    block_size - char_select
  end

end

def padding_error_oracle
  ciphertext, iv = generate
  block_size = 16
  last_char = block_size - 1
  blocks = ByteArray.from_string(ciphertext).each_slice(block_size)
  full_string = ""
  blocks.each_with_index do |block, index|
    original_iv = index > 0 ? blocks[index-1] : ByteArray.from_string(iv)

    discovered_bytes = SingleBlockOracle.new(block, original_iv).decipher

    full_string << discovered_bytes.to_s
  end

  full_string
end

puts "Resulting string:"
puts padding_error_oracle
