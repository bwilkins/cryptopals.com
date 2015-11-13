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
