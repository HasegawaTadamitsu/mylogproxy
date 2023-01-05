#!/usr/bin/ruby
# coding: utf-8

inputs =gets.chomp.split(" ").map(&:to_s)
ret = 0 
bytes_size = inputs.size
inputs.each_with_index do |val,i|
  keisuu= 2**((bytes_size - (i + 1))*8)
 
  ret += val.hex * keisuu
end
print "inputs #{inputs.join}\n"
print "output #{ret}\n"
