#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

# Output debugging info to the screen, set to false to supress this.
# The data is still stored in the logfile
$verbose = true

# Create a connection to the database
database = LibertyDatabase.new :mysqldb => "liberty2dbFinal",
                               :mysqlhost => "wildcat.ee.engr.uky.edu",
                               :logfile => "log",
                               :pvt => [1.0,1.32,-40]

#show what the hash looks like:
#powerdata = database.getAllPowerData :footprint => 'INV'
#puts powerdata.inspect


Hash powerdata = database.getAllPowerData
powerValues = Hash.new
slewValues = Hash.new


powerdata.keys.each { |pin|
    powerdata[pin].keys.each { |when|
        powerdata[pin][when].keys.each { |slew|
            powerValues[pin+when] = powerdata[pin][when][slew][".133417"] #power
            slewValues[pin+when] = slew
            }
        }
    }



scatterPlot = Plot.( slewValues, powerValues )

scatterPlot.generatePlot( :savePlot => false,
                          :title = "Power vs. Slew",



