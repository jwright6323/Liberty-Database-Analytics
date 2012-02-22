#!/usr/bin/ruby
require 'LibertyDatabase.rb'
require 'Plot.rb'

# Output debugging info to the screen, set to false to supress this.
# The data is still stored in the logfile
$verbose = true

# Create a connection to the database
database = LibertyDatabase.new :mysqldb => "LibertyFile",
                               :mysqlhost => "hendrix",
                               :logfile => "log"

# Query leakage using LibertyDatabase.getLeakage
data25  = database.getData "cell_leakage_power", :footprint => "INV",
                              :pvt => [1,1.2,25]
data_40 = database.getData "cell_leakage_power", :footprint => "INV",
                              :pvt => [1,1.2,-40]
data125 = database.getData "cell_leakage_power", :footprint => "INV",
                              :pvt => [1,1.2,125]

# Query area
area_raw = database.getData "area", :footprint => "INV"

# Create a new hash to store data across all temperatures
data = Hash.new
area = Hash.new

data25.each { |key,val|
  data.store(key+"@25",val)
}
data_40.each { |key,val|
  data.store(key+"@-40",val)
}
#data125.each { |key,val|
#  data.store(key+"@100",val)
#}
area_raw.each { |key,val|
  area.store(key+"@25",val)
  area.store(key+"@-40",val)
#  area.store(key+"@125",val)
}

plot = Plot.new(area,data)

# Plot to screen.  Use plotToFile to plot to a gif image
plot.generatePlot :title => "Leakage vs. Area for multiple PVTs",
                  :filename => "pvt",
                  :x_label => "area",
                  :y_label => "leakage",
                  :dataLabels => true

