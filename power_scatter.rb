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
powerdata = database.getAllPowerData :footprint => 'INV'

puts powerdata.inspect
