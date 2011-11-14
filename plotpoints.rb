#!/usr/bin/env ruby
#Danny Peters, Edward Poore, John Wright
#2011

# basic test to use gnuplot in ruby
# plots a curve as defined by x and y

require 'rubygems'
require 'gnuplot'


# log_x and log_y - bool - turn log scales on (true) or off (false)
# x and y are arrays of data to plot (must be the same size)
# filename - string - determines the name of the generated plot and data file (filename.dat)

def plotpoints(x, y, x_label, y_label, title, log_x, log_y, filename="out")

    if(x.length == y.length)

        # generate a datafile to use in gnuplot
        datfile = filename + ".dat"

        newfile = File.new(datfile, "w")
            (0..x.size).collect do |i|
                newfile.puts "#{x[i]}\t#{y[i]}"
            end

        newfile.close



        # plot data
        Gnuplot.open do |gp|
            Gnuplot::Plot.new( gp ) do |plot|
              # plot to a file
              plot.terminal "gif"
              plot.output filename + ".gif"

              #apply title/labels 
              plot.title   title
              plot.ylabel  y_label
              plot.xlabel  x_label

        # check if graphs need to be logscaled
              if (log_x)
                    plot.arbitrary_lines << "set logscale x"
              end
          
              if (log_y)
                    plot.arbitrary_lines << "set logscale y"
              end

              plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
                ds.with = "point"
                ds.notitle
                      
              end
            end
        end    
    
    else
        puts "X and Y are different sizes"
    end


end
