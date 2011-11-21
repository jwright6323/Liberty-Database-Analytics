#!/usr/bin/ruby
require 'plotpoints.rb'
require 'plothist.rb'
require 'LibertyDatabase.rb'

# show query stuff
$verbose = true

#Declare a test database on wildcat
#test = LibertyDatabase.new :mysqlhost => "wildcat.ee.engr.uky.edu", :logfile => "log"

# Get the footprint name for INVM1S, print it, then get area and leakage for all cells in that footprint
#t = "INV" # test.getCellFootprint("INVM1S")
#puts t
#puts test.getData "area", :footprint => t
#areas = test.getData(:area,:footprint =>  t)
#lkgs  = test.getData(:cell_leakage_power, :footprint => t)


#  Array Declarations
#x = Array.new
#y = Array.new
#z = Array.new

#  Push query data into arrays
#  areas.keys.each { |key|
#  x.push(areas[key].to_f)
#  y.push(lkgs[key].to_f)
#  z.push(lkgs[key].to_f / areas[key].to_f)
#  }

# If no data can be gotten from the database, use this test data
#x = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
#y = [1, 3, 2, 5, 6, 5, 6, 9, 10, 9]



# Plotting Function Calls
#plotpoints(x, y, "Area (um2)", "Leakage (uW)", "A vs. Lkg", :linreg => true )
#plotpoints(x, z, "Area (um2)", "Leakage/Area (uW/um2)", "A/Lkg", false, false)




# Close any open database objects
#test.close



