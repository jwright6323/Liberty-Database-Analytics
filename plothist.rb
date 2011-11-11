#!/usr/bin/env ruby
# basic test to use gnuplot in ruby
# plots a curve as defined by x and y

require 'rubygems'
require 'gnuplot'


def plothist(numBins, x, x_label, title, min=nil, max=nil, filename ="out")
   
    # if numBins is zero...
    if(numBins <= 0)
        numBins = 1
    end

    # if no max and min are specified, set them
    if(min == nil or max == nil)
        max = x.max
        min = x.min
    end

    bw = (max.to_f - min.to_f) / numBins.to_f
    x_count = Array.new
    x_axis = Array.new

    (1..numBins).each {|n|
       count = 0
       x.each {|v|
            if(((min.to_f + (n.to_f-1) * bw.to_f) < (v.to_f)) and ((v.to_f) <= (min.to_f + n.to_f * bw.to_f)))
                count = count + 1
            end
            }
       x_count.push(count)
       }
                
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
    


