require(File.expand_path('../../../../util.rb', __FILE__))

INPUT = Base64.decode64("L77na/nrFsKvynd6HzOoG7GHTLXsTVu9qvY/2syLXzhPweyyMTJULu/6/kXX0KSvoOLSFQ==")
KEY = 'YELLOW SUBMARINE'


output = CTR_crypt(INPUT, KEY, 0)
puts "Decrypted:"
puts output
puts
puts "Re-encrypted matches?"
puts CTR_crypt(output, KEY, 0) == INPUT

