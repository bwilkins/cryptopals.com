#!/usr/bin/env ruby
require(File.expand_path('../../../../util.rb', __FILE__))

encrypted_messages = File.readlines(File.expand_path('../20.txt', __FILE__)).map(&:chomp).map do |x|
  Base64.decode64(x)
end

max_decryptable = encrypted_messages.map(&:length).min
encrypted_messages.map! do |message|
  ByteArray.from_string(message[0, max_decryptable])
end

message_inverses = encrypted_messages.map(&:not).map(&:neg)


message_key = message_inverses.inject(ByteArray.new([0xFF]*max_decryptable)) do |memo, key|
  memo.and(key)
end

puts message_key.inspect

encrypted_messages.each do |message|
  puts message.xor(message_key)
end
