#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'
#
# Produces a Plot of max capacitance driven vs. area for all cells.
#
#
# show query stuff
$verbose = true

#Declare a database on wildcat
database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate", :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"

area = Hash.new
area = database.getData( "area" ) # Get area values for each cell
 
output_maxcaps = database.getOutputMaxCap # Get summed max caps for all cells with output pins

# If a cell has no output pins, remove it from the area hash
area.keys.each { |key|
    unless output_maxcaps.keys.include?(key)
      area.delete(key)
    end
}

testplot = Plot.new( area, output_maxcaps )
testplot.plotToScreen( :title => "Max Capacitance Driven vs. Area", :x_label => "Area", :y_label => "Max Capacitance Driven", :filename => "maxcapVsArea", :linreg => true, :outlierAnalysis => [true,1] )
testplot.findOutliers( filename = "maxcapVsAreaOutliers.dat", k = 2)



