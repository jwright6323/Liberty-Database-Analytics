#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

#x = (0..50).collect { |val| val.to_f }
#y = x.collect { |val| val ** 2 }

#plot(x, y, "x", "x^2", "X squared")
$verbose = true
test = LibertyDatabase.new :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"
lkg = test.getData "cell_leakage_power"
area = test.getData "area"
p = Plot.new area,lkg

#puts test.getLeakage(:cells => "INVM1S").inspect

#fh = File.new("testout","w")
#x = Array.new
#test.getLeakage.each do |cell_name,leakage_data|
#  min = leakage_data.values.sort[0]
#  max = leakage_data.values.sort[-1]
#  diff = (max-min)*200/(max+min)
#  x.push(diff)
#  fh.puts("#{cell_name},#{diff}")
#end
#fh.close
#plothist( 10, x, "%diff", "%diff between BC and WC when condition leakages" )
#t = test.getCellFootprint("INVM1S")
#puts t
#puts test.getData "area", :footprint => t
#areas = test.getData :area
#lkgs  = test.getData :cell_leakage_power

#x = Array.new
#y = Array.new
#z = Array.new

#areas.keys.each { |key|
#  x.push(areas[key].to_f)
#  y.push(lkgs[key].to_f)
#  z.push(lkgs[key].to_f / areas[key].to_f)
#}
#plotpoints(x, y, "Area (um2)", "Leakage (uW)", "A vs. Lkg", false, false)
#plotpoints(x, z, "Area (um2)", "Leakage/Area (uW/um2)", "A/Lkg", false, false)
#def plothist(numBins, x, x_label, title, min=nil, max=nil, filename ="out")
#plothist(10, z, "Leakage/Area (uW/um2)", "Area per Lkg")
test.close
