#!/usr/bin/ruby
require 'plot.rb'
require 'LibertyDatabase.rb'

#x = (0..50).collect { |val| val.to_f }
#y = x.collect { |val| val ** 2 }

#plot(x, y, "x", "x^2", "X squared")

test = LibertyDatabase.new :mysqlhost => "wildcat.ee.engr.uky.edu"

obj = test.getData "area"
puts obj.inspect
test.close
