require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'

def ECB_encrypt_rand_key(input_str)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 0
  $cipher_key ||= cipher.random_key
  cipher.key = $cipher_key
  cipher.update(input_str) + cipher.final
end

def ECB_decrypt_rand_key(input_str)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.decrypt
  cipher.padding = 0
  $cipher_key ||= cipher.random_key
  cipher.key = $cipher_key
  cipher.update(input_str) + cipher.final
end

def CBC_encrypt(input, iv)
  input = ByteArray.from_string(input)
  _iv = iv
  output = ""

  input.each_slice(16).map do |byte_slice|
    byte_slice.pad!(16)
    byte_slice.xor!(_iv)
    output << (_iv = ECB_encrypt_rand_key(byte_slice.to_s))
    _iv = ByteArray.from_string(_iv)
  end
  output
end

def CBC_decrypt(input, iv)
  input = ByteArray.from_string(input)
  _iv = iv
  output = ""

  input.each_slice(16).map do |byte_slice|
    byte_slice0 = ByteArray.from_string(ECB_decrypt_rand_key(byte_slice.to_s))
    output << byte_slice0.xor(_iv).to_s
    _iv = byte_slice
  end
  output
end

def generate_encrypted_data(input)
  input = input.gsub(';','%59').gsub('=', '%61')
  $iv ||= ByteArray.new(random_bytea(16))
  plain_text = 'comment1=cooking%20MCs;userdata=' + input + ';comment2=%20like%20a%20pound%20of%20bacon'
  CBC_encrypt(plain_text, $iv)
end

def check_userdata(input)
  plaintext = CBC_decrypt(input, $iv)
  !!(/;admin=true;/ =~ plaintext)
end

def get_admin
  desired_input = ';admin=true;'
  placeholder = 'x' * desired_input.length
  block_size = 16 # Haven't figured this one out properly for CBC yet
  ciphertext = generate_encrypted_data(placeholder)
  test = ciphertext
  possible_positions_per_block = block_size - desired_input.length
  block = -1
  found = check_userdata(test)

  until found
    block +=1
    possible_positions_per_block.times do |position|
      front_padding = position
      padded_placeholder = pad_block(('x' * front_padding) + placeholder, block_size)
      padded_desired = pad_block(('x' * front_padding) + desired_input, block_size)

      ba = ByteArray.from_string(ciphertext)
      slices = ba.each_slice(block_size)
      slice = slices[block]
      slice.xor!(padded_placeholder)
      slice.xor!(padded_desired)
      test = slices.inject("") do |str, slice|
        str << slice.to_s
        str
      end
      found = check_userdata(test)
      break if found
    end
  end

  return test
end

puts "Ciphertext to gain admin:"
puts get_admin.inspect

exit
