#!/usr/bin/ruby
require 'plot.rb'

x = (0..50).collect { |val| val.to_f }
y = x.collect { |val| val ** 2 }

plot(x, y, "x", "x^2", "X squared")
