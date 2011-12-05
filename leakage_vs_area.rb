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
#lkgPerArea = Hash.new

area = database.getData( "area" )
lkg  = database.getData( "cell_leakage_power" )

leakagePerArea = Hash.new

area.keys.each { |key|
    leakagePerArea[key] = lkg[key].to_f / area[key].to_f
}



testplot = Plot.new( area, lkg )
testplot.plotToFile( :title => "Leakage Vs. Area for All Cells", :x_label => "Area in square microns", :y_label => "Leakage in microwatts", :filename => "leakageVsArea/lkgVsAreaAll", :linreg => true, :outlierAnalysis => [true,2] )
testplot.findOutliers( "leakageVsArea/lkgVsAreaAllOutliers.dat", k = 2 )

lkgUnitArea = Plot.new( area, leakagePerArea )
lkgUnitArea.plotToFile( :title => "Leakage per Unit Area vs Area for all cells", :x_label => "Area in square microns", :y_label => "Leakage (microwatts) per square micron", :filename => "leakageVsArea/lkgUnitAreaAll", :linreg => true, :outlierAnalysis => [true,2] )

hist = Plot.new( leakagePerArea )
hist.plotToFile( :title => "Leakage per Unit Area for all cells", :x_label => "Leakage in microwatts per square micron", :filename => "leakageVsArea/lkgUnitAreaAllHist", :numBins => 50 )

