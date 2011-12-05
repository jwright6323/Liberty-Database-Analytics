#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

#
# Generate plots to display relationship between leakage and drivestrength.
#
#
#
$verbose = true

filename = "leakage_vs_maxcap"


# Declare a database
database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate", :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"

leakage = Hash.new
leakage = database.getData("cell_leakage_power") # Get cell leakage powers

output_maxcaps = Hash.new
output_maxcaps = database.getOutputMaxCap # Get summed max caps for all cells

removeCount = 0
leakage.keys.each { |key|
    unless output_maxcaps.keys.include?(key)
        leakage.delete(key)
        #puts "removing #{key} from the hash"
        removeCount = removeCount + 1
    end
}

scatterplot = Plot.new(output_maxcaps,leakage)
scatterplot.plotToScreen( :title => "Leakage Power vs. Max Capacitance Driven", :x_label => "Max Capacitance Driven", :y_label => "Leakage Power", :linreg => true, :filename => filename, :outlierAnalysis => [true,2] ) 
scatterplot.findOutliers((filename + ".outlier"), k = 2)


