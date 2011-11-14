#!/usr/bin/ruby -w0
# PlottingTools.rb
# 2011-11-13
# John Wright, Daniel Peters, Edward Poore
# jcwr@cypress.com, danmanstx@gmail.com, edward.poore@gmail.com
#

require 'rubygems'
require 'gnuplot'

class PlottingTools

  def plotPoints(x, y, x_label, y_label, title, log_x, log_y, filename="out")
      defaults = { :logx => false,
                   :logy => false,
                   :filename => "out" }
      options = defaults.merge(options)
      log_x = options[:logx]
      log_y = options[:logy]
      filename = options[:filename]
      if(x.length == y.length) then
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

end #PlottingTools
