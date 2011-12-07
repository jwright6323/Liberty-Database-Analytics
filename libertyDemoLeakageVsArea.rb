#!/usr/bin/ruby

# Allows access to the LibertyDatabase class.
require 'LibertyDatabase.rb'

# Allows access to the Plot class.
require 'Plot.rb'

# 
# Demonstration of database access and plotting functionality.
#

$verbose = true 

# Declare a database object in the code so we can pull information from the database on wildcat.
database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate",
                               :mysqlhost => "wildcat.ee.engr.uky.edu",
                               :logfile => "log"

# Declare hashes to collect data into.
cell_area  = Hash.new
cell_leakage = Hash.new

# Collect the data from the database on wildcat.
# Get area values for each cell in the database.
cell_area = database.getData( "area" )
# Get leakage values for each cell in the database.
cell_leakage = database.getData( "cell_leakage_power" )


# Declare a Plot object so that we can plot the data.
plot = Plot.new( cell_area, cell_leakage )

# Generate a scatter plot on-screen.
plot.plotToScreen :title => "Leakage Power vs. Area",
                  :x_label => "Area",
                  :y_label => "Leakage",
                  :filename => "leakageVsArea",
                  :linreg => true


## Other things we could do:
#
## Add labels to all points
#plot.plotToScreen :title => "Leakage Power vs. Area",
#                  :x_label => "Area",
#                  :y_label => "Leakage",
#                  :filename => "leakageVsArea",
#                  :linreg => true,
#                  :dataLabels => true


## or just to outlier cells
#plot.plotToScreen :title => "Leakage Power vs. Area",
#                  :x_label => "Area",
#                  :y_label => "Leakage",
#                  :filename => "leakageVsArea",
#                  :linreg => true,
#                  :addOutlierLabels => 1

## We can also add lines to show outlier bounds.
#plot.plotToScreen :title => "Leakage Power vs. Area",
#                  :x_label => "Area",
#                  :y_label => "Leakage",
#                  :filename => "leakageVsArea",
#                  :linreg => true,
#                  :addOutlierLabels => 1,
#                  :doOutliers => true,
#                  :outlierK => 1

## Plot the data on log scales

## The x axis
#plot.plotToScreen :title => "Leakage Power vs. Area",
#                  :x_label => "Area",
#                  :y_label => "Leakage",
#                  :filename => "leakageVsArea",
#                  :linreg => true,
#                  :addOutlierLabels => true,
#                  :logx => true


## and the y axis
#plot.plotToScreen :title => "Leakage Power vs. Area",
#                  :x_label => "Area",
#                  :y_label => "Leakage",
#                  :filename => "leakageVsArea",
#                  :linreg => true,
#                  :addOutlierLabels => true,
#                  :logy => true

# We can also use the Plot class to generate a list of outliers based on the IQR rule.
plot.findOutliers( "leakageVsAreaAllCells.outliers", k = 1 )


















