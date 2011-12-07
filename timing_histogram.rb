#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

# Output debugging info to the screen, set to false to supress this.
# The data is still stored in the logfile
$verbose = true

# Create a connection to the database
database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate", 
                               :mysqlhost => "wildcat.ee.engr.uky.edu",
                               :logfile => "log"

# Query timing information using LibertyDatabase.getTimingData
timingdata = database.getTimingData

# Create a new hash to store the percent difference data
percent_difference = Hash.new

# Loop through the timing data and calculate the percent difference
#   between minimum and maximum values
timingdata.each { |cell,when_condition|
  # Find minimum data point
  min = when_condition.values.min
  # Find maximum data point
  max = when_condition.values.max
  # Calculate percent difference
  percent_difference.store(cell,(max-min)*200/(max+min))
}

# Create a new plot using the percent difference data
plot = Plot.new percent_difference

# Plot to screen.  Use plotToFile to plot to a gif image
plot.plotToScreen :title => "Percent Difference Between Best and Worst Case Timing per Pin by When Cond",
                  :filename => "timing",
                  :numBins => 10,
                  :x_label => "% diff"

