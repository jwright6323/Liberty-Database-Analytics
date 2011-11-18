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
                     :max => @x_data.max,
                     :logx => false,
                     :logy => false,
                     :linreg => false }                  
        
        options = defaults.merge(options)

        filename = options[:filename]
        numBins = options[:numBins]
        x_label = options[:x_label]
        y_label = options[:y_label]
        title = options[:title]
        min = options[:min]
        max = options[:max]
        logx = options[:logx]
        logy = options[:logy]
        linreg = options[:linreg]    


        if (@plottype == :histogram)
            x = Array.new
            @x_data.keys.each { |key|
                x.push(x_data[key].to_f)
            }


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
            y = Array.new
            x = Array.new
            @x_data.keys.each { |key|
                x.push(x_data[key].to_f)
            }
            @y_data.keys.each { |key|
                y.push(y_data[key].to_f)
            }

            if(@x_data.length == @y_data.length)

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
                    if (linreg)
                        plot.arbitrary_lines << "plot '#{datfile}' notitle, f(x) title 'Linear Fit'" 
                    else
                    # otherwise dont add it
                        plot.arbitrary_lines << "plot '#{datfile}'"
                    end
                end
            end    
    
        else
            puts "X and Y are different sizes"
        end
        end # scatter

    end # plotToFile

    # Generate a plot and display it on the screen
    def plotToScreen( options = {}  )
        defaults = { :filename => "out",
                     :numBins => 1,
                     :x_label => "X",
                     :y_label => "Y",
                     :title => "Title",
                     :min => @x_data.min,
                     :max => @x_data.max,
                     :logx => false,
                     :logy => false,
                     :linreg => false }                  
        
        options = defaults.merge(options)

        filename = options[:filename]
        numBins = options[:numBins]
        x_label = options[:x_label]
        y_label = options[:y_label]
        title = options[:title]
        min = options[:min]
        max = options[:max]
        logx = options[:logx]
        logy = options[:logy]
        linreg = options[:linreg]    


        if (@plottype == :histogram)
            x = Array.new
            @x_data.keys.each { |key|
                x.push(x_data[key].to_f)
            }

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
                    # plot.terminal "gif"
                    # plot.output filename + ".gif" 
                    plot.arbitrary_lines << "set xrange [" + min.to_s + ":" + max.to_s + "]"   

                    plot.data << Gnuplot::DataSet.new( [x_axis, x_count] ) do |ds|
                        ds.with = "histeps"
                        ds.notitle
                    end
                end
            end
        end

        if (@plottype == :scatter)
   
            y = Array.new
            x = Array.new
            @x_data.keys.each { |key|
                x.push(x_data[key].to_f)
            }
            @y_data.keys.each { |key|
                y.push(y_data[key].to_f)
            }



            if(@x_data.length == @y_data.length)

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
                    # plot.terminal "gif"
                    # plot.output filename + ".gif"

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
                    if (linreg)
                        plot.arbitrary_lines << "plot '#{datfile}' notitle, f(x) title 'Linear Fit'" 
                    else
                    # otherwise dont add it
                        plot.arbitrary_lines << "plot '#{datfile}'"
                    end

                end
            end    
    
        else
            puts "X and Y are different sizes"
        end
        end # scatter
    end # plotToScreen

end # Plot class

