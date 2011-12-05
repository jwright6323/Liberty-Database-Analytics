#!/usr/bin/ruby -w0
require 'analytics.rb'
require 'Plot.rb'
require 'LibertyDatabase.rb'

$verbose = true
db = LibertyDatabase.new :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log", :mysqldb => "LibertyFileUpdate"
results = db.getTimingData :footprint => 'INV'
puts "type\t\t\t\tmin\t\tavg\t\tmax"
results.each { |key,val|
  puts "#{key}\t#{val['min']}\t#{val['avg']}\t#{val['max']}"
}
