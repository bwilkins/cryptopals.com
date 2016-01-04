#!/usr/bin/env ruby
require(File.expand_path('../../../../util.rb', __FILE__))
require 'pry'


class MT19937
  def initialize(seed)
    @index = 624
    @mt = [0]*624
    @mt[0] = seed
    (1..624).each do |i|
      next if i == 0
      @mt[i] = int32(1812433253 * (@mt[i-1] ^ (@mt[i-1] >> 30)) + i)
    end
  end

  def extract_number
    twist if index >= 624

    y = mt[index]
    y = y ^ y >> 11
    y = y ^ y << 7 & 2636928640
    y = y ^ y << 15 & 4022730752
    y = y ^ y >> 18

    @index += 1
    int32(y)
  end

  private
  attr_reader :index, :mt

  def twist
    @mt.each_with_index do |state, i|
      y = int32((mt[i] & 0x80000000) + (@mt[(i + 1) % 624] & 0x7fffffff))
      x = @mt[(i + 397) & 624]
      z = x ^ y
      binding.pry if [true, false].include? z

      @mt[i] = (z) >> 1
      binding.pry if [true, false].include? y

      if y % 2 != 0
        @mt[i] = @mt[i] ^ 0x9908b0df
      end
    end
    @index = 0
  end

  def int32(num)
    0xFFFFFFFF & num
  end
end

