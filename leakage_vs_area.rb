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


testplot = Plot.new( area, lkg )
testplot.plotToScreen( :title => "Leakage Vs. Area", :x_label => "Area", :y_label => "Leakage", :filename => "lkgVsArea", :linreg => true, :outlierAnalysis => [true,1] )
testplot.findOutliers( "lkgVsAreaOutliers.dat", k = 2 )
