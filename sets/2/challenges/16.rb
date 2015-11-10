require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'

def generate_encrypted_data(input)
  input = input.gsub(';','%59').gsub('=', '%61')
  $iv ||= ByteArray.new(random_bytea(16))
  plain_text = 'comment1=cooking%20MCs;userdata=' + input + ';comment2=%20like%20a%20pound%20of%20bacon'
  CBC_encrypt(plain_text, $iv)
end

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
