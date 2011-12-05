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
area = database.getData( "area", :footprint => "INV" ) # Get area values for each cell
 
output_maxcaps = database.getOutputMaxCap # Get summed max caps for all cells with output pins

# If a cell has no output pins, remove it from the area hash
removeCount = 0
area.keys.each { |key|
    unless output_maxcaps.keys.include?(key)
      area.delete(key)
      puts "removing #{key} from the cell area hash as it has no output pins."
      removeCount = removeCount + 1
    end
}


# Generate a 1D array for maxcap per unit area
maxcapPerArea = Hash.new

output_maxcaps.keys.each { |key|
    maxcapPerArea[key] = output_maxcaps[key].to_f / area[key].to_f
}




scatterplot = Plot.new( area, output_maxcaps )
scatterplot.plotToScreen( :linreg => true, :title => "Max Capacitance Driven vs. Area for Footprint INV", :x_label => "Area", :y_label => "Max Capacitance Driven", :filename => "maxcapVsArea", :outlierAnalysis => [true,2] )
scatterplot.findOutliers( filename = "maxcapVsAreaOutliers.dat", k = 2)

unitAreaVsArea = Plot.new( area, maxcapPerArea )
unitAreaVsArea.plotToScreen( :linreg => true, :title => "Max Capacitance Driven per Unit Area vs. Area for Footprint INV", :x_label => "Area", :y_label => "Max Cap per Unit Area", :filename => "maxcapPerAreaVsArea", :outlierAnalysis => [true,2] )



#histplot = Plot.new( maxcapPerArea )
#histplot.plotToScreen( :title => "Max Capacitance Driven per Unit Area", :filename => "maxcapPerUnitArea", :numBins => 50)

# Information on cleaning up the data selection.
puts "There were #{output_maxcaps.size} samples sent to the plot"
puts "#{removeCount} cells with no output pins removed from the area hash."


