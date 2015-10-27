require(File.expand_path('../../../../util.rb', __FILE__))

file_lines = File.read(File.expand_path('../8.txt', __FILE__)).chomp.split

file_lines.each_with_index do |line, index|
  data = hexstr_to_bytea(line)
  if detect_ECB_mode(data)
    puts index+1
  end
end

