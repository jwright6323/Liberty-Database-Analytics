#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

#
# Generate plots to display relationship between leakage and drivestrength.
#
#
#
$verbose = true

filename = "leakageVsMaxcap/leakage_vs_maxcap"


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

leakagePerMaxcap = Hash.new

output_maxcaps.keys.each { |key|
    leakagePerMaxcap[key] = leakage[key].to_f / output_maxcaps[key].to_f
}



scatterplot = Plot.new(output_maxcaps,leakage)
scatterplot.plotToFile( :title => "Leakage Power vs. Max Capacitance Driven for All Cells", :x_label => "Max Capacitance Driven in pF", :y_label => "Leakage Power in microwatts", :linreg => true, :filename => filename + "ALLCELLS", :outlierAnalysis => [true,1] ) 
scatterplot.findOutliers((filename + "ALLCELLS" + ".outlier"), k = 1)

#histogram = Plot.new( leakagePerMaxcap )
#histogram.plotToScreen ( :title => "Leakage Power vs. Max Capacitance Driven for INV and BUF", :x_label => "Leakage (microwatts) per pF", :numBins => 10, :filename => filename + "INFBUF" + "HIST" )


