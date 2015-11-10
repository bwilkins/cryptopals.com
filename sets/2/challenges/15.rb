require(File.expand_path('../../../../util.rb', __FILE__))

VALID = "ICE ICE BABY\x04\x04\x04\x04"
INVALID1 = "ICE ICE BABY\x05\x05\x05\x05"
INVALID2 = "ICE ICE BABY\x01\x02\x03\x05"
VALID2 = "YELLOW SUBMARINE"
puts "#has_valid_padding?"
puts "  given a valid padded string"
puts "    it returns true? #{has_valid_padding?(VALID) == true}"
puts
puts "  given an invalid padded string"
puts "    it returns false? #{has_valid_padding?(INVALID1) == false}"
puts
puts "  given an invalid padded string"
puts "    it returns false? #{has_valid_padding?(INVALID2) == false}"
puts
puts "  given an valid string without padding"
puts "    it returns true? #{has_valid_padding?(VALID2) == true}"
puts
