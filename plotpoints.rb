#!/usr/bin/env ruby
#Danny Peters, Edward Poore, John Wright
#2011

require 'rubygems'
require 'gnuplot'


# plotpoints is a function to scatter plot two arrays of equal size.
#
# ==== Options
#
# [+:logx+] Bool. True displays the x axis on a log scale. Default is false.
# [+:logy+] Bool. True displays the y axis on a log scale. Default is false.
# [+:filename+] String. Define a filename to write data/gif to. Default is out.
# [+:linreg+] Bool. True adds a linear regression line. Default is false.
#

def plotpoints(x, y, x_label, y_label, title, options={} )
    defaults = { :logx => false,
                 :logy => false,
                 :filename => "out",
                 :linreg => false }
    options = defaults.merge(options)

    logx = options[:logx]
    logy = options[:logy]
    filename = options[:filename]
    linreg = options[:linreg]

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
              if (logx)
                    plot.arbitrary_lines << "set logscale x"
              end

              if (logy)
                    plot.arbitrary_lines << "set logscale y"
              end

        # check if a linear regression is desired
              if (linreg)
                    plot.arbitrary_lines << "f(x) = m*x + b"
                    plot.arbitrary_lines << "fit f(x) '" + datfile + "' using 1:2 via m,b"
             end

        # plot with a regression line
             if
             plot.arbitrary_lines << "plot '#{datfile}' notitle, f(x) title 'Linear Fit'"
             end



        # otherwise dont add it
             plot.arbitrary_lines << "plot '#{datfile}'"

           end
        end

    else
        puts "X and Y are different sizes"
    end


end

