#!/usr/bin/ruby
require 'plot.rb'
require 'LibertyDatabase.rb'

#x = (0..50).collect { |val| val.to_f }
#y = x.collect { |val| val ** 2 }

#plot(x, y, "x", "x^2", "X squared")

test = LibertyDatabase.new :mysqlhost => "wildcat.ee.engr.uky.edu"

areas = test.getData "area", :footprint => "INV"
lkgs  = test.getData "cell_leakage_power", :footprint => "INV"

x = Array.new
y = Array.new

areas.keys.each { |key|
  x.push(areas[key])
  y.push(lkgs[key])
}
plot(x, y, "Area (um)", "Leakage (uW)", "A vs. Lkg")

test.close
