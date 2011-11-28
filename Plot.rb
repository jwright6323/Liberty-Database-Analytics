#!/usr/bin/ruby -w0
# Plot.rb
# 2011-11-10
# Daniel Peters, Edward Poore, John Wright
# danmanstx@gmail.com, edward.poore@gmail.com, jcwr@cypress.com
#

require 'rubygems'
require 'mysql'
require 'gnuplot'
require 'analytics.rb'

# Plot is a class to generate various plots from given data.
class Plot
    attr_reader :x_data, :y_data

    # Constructor
    #
    # ==== Parameters
    # [+x+] The data to be used on the x-axis. Passed as hash.
    # [+y+] The data to be used on the y-axis. Passed as hash.
    #
    def initialize( x, y=nil )
        @x_data = x.clone
        @y_data = y.clone if y
        @plottype = :scatter

        # Check for 1D vs 2D plotting
        if (y == nil)
            @plottype = :histogram
        end
    end # initialize

    # Find outliers for a given set of data and print them to a file
    #
    # ====Parameters
    # [+filename+] A string representing the name of the file to be generated. Default is "outliers.dat".

    def findOutliers( filename = "outliers.dat" )
        if (@y_data) # Only works with 2D data. Needs to be fixed.
        # Create a hash of slopes with their keys and an array of slopes
        slopeHash = Hash.new
        slopeArray = Array.new

        @x_data.keys.each { |key|
            slopeHash[key] = @y_data[key].to_f / @x_data[key].to_f
            slopeArray.push(@y_data[key].to_f / @x_data[key].to_f)
        }

        # Perform a 5 Number Analysis on the array

        summary = Array.new
        summary = fiveNumSum( slopeArray )

        # Determine the maximum and minimum non-outlier slopes
        minSlope = summary[2] - (summary[3] - summary[1])
        maxSlope = summary[2] + (summary[3] - summary[1])

        # Select any outliers and print their cell names to a datafile

        newfile = File.new(filename, "w")
        slopeHash.keys.each { |key|
                if (slopeHash[key] > maxSlope || slopeHash[key] < minSlope)
                    newfile.puts "#{key}"
                end
        }
        newfile.close
        end
    end #findOutliers

    # Generate a plot and save it as a file.
    #
    # ==== Options
    #
    # [+:filename+] A string representing the filename for data and plot files. Default is "out".
    # [+:numBins+] The number of bins to sort histogram data into. Default is 2.
    # [+:x_label+] A string label for the x axis. Default is "X".
    # [+:y_label+] A string label for the y axis. Default is "Y".
    # [+:title+] A string title for the plot. Default is "Title".
    # [+:min+] Sets the minimum range value for histograms. Default is the smallest value in the hash passed in.
    # [+:max+] Sets the maximum range value for histograms. Default is the largest value in the hash passed in.
    # [+:logx+] Bool to apply a log scale to the x axis of a scatter plot. Default is false (off).
    # [+:logy+] Bool to apply a log scale to the y axis of a scatter plot. Default is false (off).
    # [+:linreg+] Bool to add a linear regression line to a scatter plot. Default is false (off).
    # [+:outlierAnalysis+] Bool to add outlier analysis lines. Default is false (off).
    # [+:dataLabels+] Bool to include the key of the @x_data hash at the appropriate point of the plot. Default is false (off).
    #

    def plotToFile( options={} )
        x_array = Array.new
        @x_data.keys.each { |key|
            x_array.push( @x_data[key])
        }
        
        defaults = { :filename => "out",
                     :numBins => 2,
                     :x_label => "X",
                     :y_label => "Y",
                     :title => "Title",
                     :min => x_array.min,
                     :max => x_array.max,
                     :logx => false,
                     :logy => false,
                     :linreg => false,
                     :outlierAnalysis => false,
                     :dataLabels => false }

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
        outlierAnalysis = options[:outlierAnalysis]
        dataLabels = options[:dataLabels]

        if (@plottype == :histogram)
            x = Array.new
            @x_data.keys.each { |key|
                x.push(@x_data[key].to_f)
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
  
            x_count[0] = x_count[0] + 1 # Increments the first bin to account for the minimum value not being added in 

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
                        ds.with = "boxes"
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

                    # perform outlier analysis
                    if (outlierAnalysis)

                        # generate array of slopes of data
                        yDivX = Array.new
                        @x_data.keys.each { |key|
                            yDivX.push(@y_data[key].to_f / @x_data[key].to_f)
                        }

                        # apply the 5 number summary function
                        summData = Array.new
                        summData = fiveNumSum( yDivX ) # match to new function

                        # Calculate slopes of minimum and maximum lines to show outliers
                        maxline = summData[2] + (summData[3] - summData[1])
                        minline = summData[2] - (summData[3] - summData[1])

                        # Define the minline and maxline in gnuplot
                        plot.arbitrary_lines << "a(x) = #{minline}*x"
                        plot.arbitrary_lines << "b(x) = #{maxline}*x"

                    end #outlier analysis


                    # Generate a plot string
                    plotString = "plot '#{datfile}'"

                    # add linear regression
                    if (linreg)
                        plotString = plotString + " notitle, f(x) title 'Linear Fit'"
                        # Old Method
                        #plot.arbitrary_lines << "plot '#{datfile}' notitle, f(x) title 'Linear Fit'"
                    end

                    # plot with outlier analysis
                    if (outlierAnalysis)
                        plotString = plotString + ", a(x) title 'Minimum', b(x) title 'Maximum'"
                    end
                    # add data point names if desired
                    if (dataLabels)
                        @x_data.keys.each { |key|
                            plot.arbitrary_lines << "set label '#{key}' at #{@x_data[key]}, #{@y_data[key]}"
                        }
                    end

                    plot.arbitrary_lines << plotString
                end
            end
        else
            puts "X and Y are different sizes"
        end # x y size check
        end # scatter

    end # plotToFile

    # Generate a plot and display it on the screen.
    #
    # ==== Options
    #
    # [+:filename+] A string representing the filename for data files. Default is "out".
    # [+:numBins+] The number of bins to sort histogram data into. Default is 2.
    # [+:x_label+] A string label for the x axis. Default is "X".
    # [+:y_label+] A string label for the y axis. Default is "Y".
    # [+:title+] A string title for the plot. Default is "Title".
    # [+:min+] Sets the minimum range value for histograms. Default is the smallest value in the hash passed in.
    # [+:max+] Sets the maximum range value for histograms. Default is the largest value in the hash passed in.
    # [+:logx+] Bool to apply a log scale to the x axis of a scatter plot. Default is false (off).
    # [+:logy+] Bool to apply a log scale to the y axis of a scatter plot. Default is false (off).
    # [+:linreg+] Bool to add a linear regression line to a scatter plot. Default is false (off).
    # [+:outlierAnalysis+] Bool to add outlier analysis lines. Default is false (off).
    # [+:dataLabels+] Bool to include the key of the @x_data hash at the appropriate point of the plot. Default is false (off).
    #

    def plotToScreen( options = {}  )
        x_array = Array.new
        @x_data.keys.each { |key|
            x_array.push( @x_data[key] )
        }
                
        defaults = { :filename => "out",
                     :numBins => 2,
                     :x_label => "X",
                     :y_label => "Y",
                     :title => "Title",
                     :min => x_array.min,
                     :max => x_array.max,
                     :logx => false,
                     :logy => false,
                     :linreg => false,
                     :outlierAnalysis => false,
                     :dataLabels => false }

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
        outlierAnalysis = options[:outlierAnalysis]
        dataLabels = options[:dataLabels]

        if (@plottype == :histogram)
            x = Array.new
            @x_data.keys.each { |key|
                x.push(@x_data[key].to_f)
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

            x_count[0] = x_count[0] + 1 # Increments the first bin to account for the minimum value not being added in 

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
                        ds.with = "boxes"
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

                        # perform outlier analysis
                        if (outlierAnalysis)

                            # generate array of slopes of data
                            yDivX = Array.new
                            @x_data.keys.each { |key|
                                yDivX.push(@y_data[key].to_f / @x_data[key].to_f)
                            }

                            # apply the 5 number summary function
                            summData = Array.new
                            summData = yDivX.fiveNumSum # match to new function

                            # Calculate slopes of minimum and maximum lines to show outliers
                            maxline = summData[2] + (summData[3] - summData[1])
                            minline = summData[2] - (summData[3] - summData[1])

                            # Define the minline and maxline in gnuplot
                            plot.arbitrary_lines << "a(x) = #{minline}*x"
                            plot.arbitrary_lines << "b(x) = #{maxline}*x"

                        end #outlier analysis

                        # Construct plot string
                        plotString = "plot '#{datfile}'"

                        # plot with a regression line
                        if (linreg)
                            plotString = plotString + " notitle, f(x) title 'Linear Fit'"
                            # old method
                            #plot.arbitrary_lines << "plot '#{datfile}' notitle, f(x) title 'Linear Fit'"
                        end

                        # plot with outlier analysis
                        if (outlierAnalysis)
                            plotString = plotString + ", a(x) title 'Minimum', b(x) title 'Maximum'"
                        end

                        # add data point names if desired
                        if (dataLabels)
                            @x_data.keys.each { |key|
                            plot.arbitrary_lines << "set label '#{key}' at #{@x_data[key]}, #{@y_data[key]}"
                            }
                        end

                        plot.arbitrary_lines << plotString

                    end
                end

            else
                puts "X and Y are different sizes"
            end
        end # scatter
    end # plotToScreen

end # Plot class

