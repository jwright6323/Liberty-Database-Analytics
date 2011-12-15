#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'
#
# Produces a Plot of max capacitance driven vs. area for all cells.
#
#
#
# show query stuff
$verbose = true

#Declare a database on wildcat
database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate",
                               :mysqlhost => "wildcat.ee.engr.uky.edu",
                               :logfile => "log"

# Get area values for all cells
area = Hash.new
area = database.getData( "area", :footprint => "INV" ) 
area.merge! database.getData( "area", :footprint => "BUF" )

# Get max capacitance values for cells within INV and BUF
output_maxcaps = database.getOutputMaxCap( :footprint => "INV") 
output_maxcaps.merge!(database.getOutputMaxCap( :footprint => "BUF"))


# Generate a 1D array for maxcap per unit area
maxcapPerArea = Hash.new

output_maxcaps.keys.each { |key|
    maxcapPerArea[key] = output_maxcaps[key].to_f / area[key].to_f
}

scatterplot = Plot.new( area, output_maxcaps )
scatterplot.generatePlot( :addOutlierLabels => 1,
                          :logx => true,
                          :logy => true, 
                          :savePlot => false, 
                          :title => "Max Capacitance Driven vs. Area for INV and BUF", 
                          :x_label => "Area in square microns", 
                          :y_label => "Max Capacitance Driven in pF", 
                          :filename => "maxcapVsAreaINVBUF" )
                            
scatterplot.findOutliers( filename = "maxcapVsArea/maxcapVsAreaOutliersINVBUF", k = 1)

unitAreaVsArea = Plot.new( area, maxcapPerArea )
unitAreaVsArea.generatePlot( :dataLabels => true, 
                             :savePlot => false, 
                             :title => "Max Capacitance Driven per Unit Area vs. Area for INV and BUF", 
                             :x_label => "Area in square microns", 
                             :y_label => "Max Cap per Unit Area (pF/square micron)", 
                             :filename => "maxcapPerAreaVsAreaINVBUF" )


histplot = Plot.new( maxcapPerArea )
histplot.generatePlot( :savePlot => false , 
                       :title => "Max Capacitance Driven per Unit Area for INV and BUF", 
                       :filename => "maxcapVsArea/maxcapPerUnitAreaHistINVBUF", 
                       :numBins => 10, 
                       :x_label => "pF per square micron" )


