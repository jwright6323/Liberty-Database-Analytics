#!/usr/bin/env ruby
# basic test to use gnuplot in ruby
# plots a curve as defined by x and y

require 'rubygems'
require 'gnuplot'


#  log_x and log_y are bool values to check if logscale axes are desired

def plotpoints(x, y, x_label, y_label, title, log_x, log_y, filename="out")

    if(x.length == y.length)

        # generate a datafile to use in gnuplot
        datfile = filename + ".dat"

        newfile = File.new(datfile, "w")
            (0..x.size).collect do |i|
                newfile.puts "#{x[i]}\t#{y[i]}"
            end

        newfile.close

        Gnuplot.open do |gp|
            Gnuplot::Plot.new( gp ) do |plot|
              # plot to a file
              plot.terminal "gif"
              plot.output filename + ".gif"

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
