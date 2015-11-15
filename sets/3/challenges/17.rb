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

def padding_error_oracle
  ciphertext, iv = generate
  block_size = 16
  last_char = block_size - 1
  blocks = ByteArray.from_string(ciphertext).each_slice(block_size)
  full_string = []
  blocks.each_with_index do |block, index|
    original_iv = index > 0 ? blocks[index-1] : ByteArray.from_string(iv)
    decipher_iv = ByteArray.new([0]*16)
    discovered_bytes = []
    char_select = last_char

    while char_select >= 0
      found = false

      (char_select..last_char).to_a.each do |char|
        decipher_iv[char] -= 1
      end

      while not found && (decipher_iv[char_select] < 0x100)
        decipher_iv[char_select] += 1
        found = begin
          check(block.to_s, decipher_iv.to_s)
        rescue
          false
        end
      end
      found = false

      intermediate = ByteArray.new([decipher_iv[char_select]]).xor(block_size - char_select)
      char = intermediate.xor(original_iv[char_select].ord)
      puts char[0]
      discovered_bytes.unshift(char)

      char_select -= 1
    end
    full_string.concat(discovered_bytes)
  end

  full_string
end

puts "Resulting string:"
puts padding_error_oracle
