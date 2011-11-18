#!/usr/bin/ruby -w0
# Plot.rb
# 2011-11-10
# Daniel Peters, Edward Poore, John Wright
# danmanstx@gmail.com, edward.poore@gmail.com, jcwr@cypress.com
#

require 'rubygems'
require 'mysql'

# Plot is a class to generate various plots from given data.
class Plot
    attr_reader :x_data, :y_data

    def initialize( x, y=nil )
        @x_data = x.clone
        @y_data = y.clone
        @plottype = :scatter

        # Check for 1D vs 2D plotting
        if (y_data == nil)
            @plottype = :histogram
        end
    end # initialize

    # Generate a plot and save it as a file
    def plotToFile( options={} )
        defaults = { :filename => "out",
                     :numBins => 1,
                     :x_label => "X",
                     :y_label => "Y",
                     :title => "Title",
                     :min => @x_data.min,
                     :max => @x_data.max }                  
        
        
        options = defaults.merge(options)

        filename = options[:filename]
        numBins = options[:numBins]
        x_label = options[:x_label]
        y_label = options[:y_label]
        title = options[:title]
        min = options[:min]
        max = options[:max]

        if (@plottype == :histogram)
    
    
            bw = (max.to_f - min.to_f) / numBins.to_f
            x_count = Array.new
            x_axis = Array.new

            # checks which values belong in each bin. Edgecases go to the higher bin.
            (1..numBins).each {|n|
                count = 0
                x.each {|v|
            
                if(((min.to_f + (n.to_f-1) * bw.to_f) < (v.to_f)) and ((v.to_f) <= (min.to_f + n.to_f * bw.to_f)))
                    count = count + 1
                end
                }
            x_count.push(count)
            }

# generates the x axis
     (1..numBins).each {|n|
        x_axis.push(min.to_f + (0.5*bw.to_f + bw.to_f * (n-1)))
        }

        Gnuplot.open do |gp|
            Gnuplot::Plot.new( gp ) do |plot|
              plot.title   title
              plot.ylabel  "Frequency"
              plot.xlabel  x_label
              plot.terminal "gif"
              plot.output filename + ".gif" 
              plot.arbitrary_lines << "set xrange [" + min.to_s + ":" + max.to_s + "]"   

              plot.data << Gnuplot::DataSet.new( [x_axis, x_count] ) do |ds|
                ds.with = "histeps"
                ds.notitle
                end
              end
        end

          







        end

        if (@plottype == :scatter)

        end
        






    end # plotToFile

    # Generate a plot and display it on the screen
    def plotToScreen(string plottype)

    end # plotToScreen

    












end # Plot class

