#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

$verbose = true

database = LibertyDatabase.new :mysqldb => "LibertyFileUpdate", :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"

timingdata = database.getTimingData

pctdiff = Hash.new

timingdata.each { |cell,whens|
  min = whens.values.min
  max = whens.values.max
  pctdiff.store(cell,(max-min)*200/(max+min))
}

plot = Plot.new pctdiff
plot.plotToScreen :title => "Percent Difference Between Best and Worst Case Timing per Pin by When Cond", :filename => "timing", :numBins => 10, :x_label => "% diff"
