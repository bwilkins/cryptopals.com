require(File.expand_path('../../../../util.rb', __FILE__))
require 'openssl'
require 'uri'

def profile_for(email)
  URI.encode_www_form(
    "email" => email,
    "uid" => 10,
    "role" => "user"
  )
end

def profile_from(qs)
  URI.decode_www_form(qs)
end

def encrypt(input_str)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.encrypt
  cipher.padding = 1
  $cipher_key ||= cipher.random_key
  cipher.key = $cipher_key
  cipher.update(input_str) + cipher.final
end

def decrypt(input_str)
  cipher = OpenSSL::Cipher.new('AES-128-ECB')
  cipher.decrypt
  cipher.padding = 1
  $cipher_key ||= cipher.random_key
  cipher.key = $cipher_key
  cipher.update(input_str) + cipher.final
end

def encrypted_profile_for(email)
  encrypt(profile_for(email))
end

def decrypt_profile_from(blob)
  profile_from(decrypt(blob)).to_h
end

secret_length = discover_secret_length do |input|
  encrypted_profile_for(input)
end
pad_block = encrypted_profile_for('x'*(secret_length + 1))[-16, 16]

admin_start_block = encrypted_profile_for('xxxxxxxxxx' + 'admin')[16,16]
role_eq_block = encrypted_profile_for('foo@exa.com')[16,16]
email_set_block = encrypted_profile_for('foo@exa.com')[0,16]


hax_block = email_set_block + role_eq_block + admin_start_block + pad_block

profile = decrypt_profile_from(hax_block)

puts "Profile role is admin?: #{profile["role"] == "admin"}"

#require 'pry'
#binding.pry
#exit
