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


area = database.getData( "area", :footprint => "INV" )
area.merge!(database.getData( "area", :footprint => "BUF" ))

lkg = database.getData( "cell_leakage_power", :footprint => "INV" )
lkg.merge!(database.getData( "cell_leakage_power", :footprint => "BUF" ))


leakagePerArea = Hash.new

area.keys.each { |key|
    leakagePerArea[key] = lkg[key].to_f / area[key].to_f
}



testplot = Plot.new( area, lkg )

testplot.plotToFile( :title => "Leakage Vs. Area for INV and BUF", :x_label => "Area in square microns", :y_label => "Leakage in microwatts", :filename => "dataLabelDemo/allLabels", :linreg => true, :dataLabels => true )

#testplot.plotToFile( :title => "Leakage Vs. Area for INV and BUF", :x_label => "Area in square microns", :y_label => "Leakage in microwatts", :filename => "logScaleDemo/original", :linreg => true  )
# testplot.findOutliers( "dataLabelDemo/lkgVsAreaINVBUFOutliers.dat", k = 1 )
#testplot.plotToFile( :title => "Leakage Vs. Area for INV and BUF", :x_label => "Area in square microns", :y_label => "Leakage in microwatts", :filename => "logScaleDemo/xLog", :logx => true, :linreg => true )
#testplot.plotToFile( :title => "Leakage Vs. Area for INV and BUF", :x_label => "Area in square microns", :y_label => "Leakage in microwatts", :filename => "logScaleDemo/yLog", :logy => true, :linreg => true )
#testplot.plotToFile( :title => "Leakage Vs. Area for INV and BUF", :x_label => "Area in square microns", :y_label => "Leakage in microwatts", :filename => "logScaleDemo/xyLog", :logx => true, :logy => true, :linreg => true )
#lkgUnitArea = Plot.new( area, leakagePerArea )
#lkgUnitArea.plotToFile( :title => "Leakage per Unit Area vs Area for INV and BUF", :x_label => "Area in square microns", :y_label => "Leakage (microwatts) per square micron", :filename => "leakageVsArea/lkgUnitAreaINVBUF", :linreg => true, :outlierAnalysis => [true,1] )

#hist = Plot.new( leakagePerArea )
#hist.plotToFile( :title => "Leakage per Unit Area for INV and BUF", :x_label => "Leakage in microwatts per square micron", :filename => "leakageVsArea/lkgUnitAreaINVBUFHist", :numBins => 10 )

