#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

# 
# Produces a plot of leakage vs. area for all cells.
#
#

# show query stuff
$verbose = true

#Declare a test database on wildcat
database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate", :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"

area = Hash.new
lkg = Hash.new

area = database.getData( "area" )
#area = database.getData( "area", :footprint => "INV" )
#area.merge!(database.getData( "area", :footprint => "BUF" ))

lkg = database.getData( "cell_leakage_power" )
#lkg = database.getData( "cell_leakage_power", :footprint => "INV" )
#lkg.merge!(database.getData( "cell_leakage_power", :footprint => "BUF" ))


leakagePerArea = Hash.new

area.keys.each { |key|
    leakagePerArea[key] = lkg[key].to_f / area[key].to_f
}



testplot = Plot.new( area, lkg )

testplot.generatePlot( :savePlot => true, 
                       :linreg => false, 
                       :title => "Leakage Vs. Area for All Cells", 
                       :x_label => "Area in square microns", 
                       :y_label => "Leakage in microwatts", 
                       :filename => "leakageVsArea/lkgVsAreaAC" )

testplot.findOutliers( "lkgVsAreaAC", 1 )

testplot2 = Plot.new( area, leakagePerArea )
testplot2.generatePlot( :addOutlierLabels => 2, 
                        :logy => true, 
                        :savePlot => false, 
                        :title => "Leakage Per Unit Area for All Cells", 
                        :x_label => "Area in square microns", 
                        :y_label => "Leakage in microwatts", 
                        :filename => "leakageVsArea/lkgVsUnitAreaAC" )

testplot3 = Plot.new( leakagePerArea )
testplot3.generatePlot( :savePlot => true, 
                        :numBins => 20, 
                        :title => "Leakage Per Unit Area for All Cells", 
                        :x_label => "Microwatts per square micron", 
                        :filename => "leakageVsArea/lkgUnitAreaHistAC" )



