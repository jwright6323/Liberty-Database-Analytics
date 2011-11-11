#!/usr/bin/ruby
require 'plotpoints.rb'
require 'plothist.rb'
require 'LibertyDatabase.rb'

#x = (0..50).collect { |val| val.to_f }
#y = x.collect { |val| val ** 2 }

#plot(x, y, "x", "x^2", "X squared")
$verbose = true
test = LibertyDatabase.new :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"
t = test.getCellFootprint("INVM1S")
puts t
#puts test.getData "area", :footprint => t
areas = test.getData "area"
lkgs  = test.getData "cell_leakage_power"

x = Array.new
y = Array.new
z = Array.new

areas.keys.each { |key|
  x.push(areas[key].to_f)
  y.push(lkgs[key].to_f)
  z.push(lkgs[key].to_f / areas[key].to_f)
}
plotpoints(x, y, "Area (um2)", "Leakage (uW)", "A vs. Lkg", false, false)
#plotpoints(x, z, "Area (um2)", "Leakage/Area (uW/um2)", "A/Lkg", false, false)
#def plothist(numBins, x, x_label, title, min=nil, max=nil, filename ="out")
plothist(10, z, "Leakage/Area (uW/um2)", "Area per Lkg")
test.close
