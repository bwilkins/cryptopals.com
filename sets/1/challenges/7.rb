require 'base64'
require 'openssl'

KEY='YELLOW SUBMARINE'

cipher = OpenSSL::Cipher.new('AES-128-ECB')

cipher.decrypt
cipher.key = KEY
file_contents = File.read(File.expand_path('../7.txt', __FILE__)).chomp
data = Base64.decode64(file_contents)

puts cipher.update(data) + cipher.final


