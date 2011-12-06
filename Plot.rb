#!/usr/bin/ruby -w0
# Plot.rb
# 2011-11-10
# Daniel Peters, Edward Poore, John Wright
# danmanstx@gmail.com, edward.poore@gmail.com, jcwr@cypress.com
#

require 'gnuplot.rb' # Includes the gnuplot gem from the local directory if it is not installed in rubygems
require 'rubygems'
require 'mysql'
# require 'gnuplot' # Include the ruby gem gnuplot if it is installed in gnuplot. Definition above (should) take care of both calls though.
require 'analytics.rb'

# Plot is a class to generate various plots from given data.
class Plot
    attr_reader :x_data, :y_data, :outlier_data

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
        @outlier_data = Hash.new

        # Check for 1D vs 2D plotting
        if (y == nil)
            @plottype = :histogram
        end
    end # initialize
    
    #
    # Find outliers for a given set of data and print them to a file. Outliers are defined as any numbers that lie outside median +- k(q3-q1)
    # 
    # ====Parameters
    # [+filename+] A string representing the name of the file to be generated. Default is "outliers.dat".
    # [+k+] Number of IQRs to check outliers against. Default is 1.
    #

    def findOutliers( filename = "outliers.dat", k = 1 )
        if ( @y_data != nil ) # 2D Plotting
            # Create a hash of slopes with their keys and an array of slopes
            slopeHash = Hash.new
            slopeArray = Array.new

            @x_data.keys.each { |key|
                slopeHash[key] = @y_data[key].to_f / @x_data[key].to_f
                slopeArray.push(@y_data[key].to_f / @x_data[key].to_f)
            }

            # Perform a 5 Number Analysis on the array

            summary = Array.new
            summary = slopeArray.fiveNumSum

            # Determine the maximum and minimum non-outlier slopes
            minSlope = summary[2] - k * (summary[3] - summary[1])
            maxSlope = summary[2] + k * (summary[3] - summary[1])

            # Select any outliers and print their cell names to a datafile

            newfile = File.new(filename, "w")
            newfile.puts "Outlier bounds are " + minSlope.to_s + " and " + maxSlope.to_s + "."
            newfile.puts "k = #{k}"
            slopeHash.keys.each { |key|
                    if (slopeHash[key] > maxSlope || slopeHash[key] < minSlope)
                        newfile.puts "#{key}"
                        @outlier_data[key] = 0 # Generate a hash with keys corresponding to outlier names
                    end
            }
            newfile.close
        end # 2D Plotting

        if ( @y_data == nil) # For 1D Plotting
            x_array = Array.new
            @x_data.keys.each { |key|
                x_array.push( @x_data[key])
            }
            
            # 5 Number Analysis on Data
            summary = Array.new
            summary = x_array.fiveNumSum

            # Determine the max and min non-outliers
            minOut = summary[2] - k * (summary[3] - summary[1])
            maxOut = summary[2] + k * (summary[3] - summary[1])
            
            # Select any outliers and print their cell names to a datafile

            newfile = File.new(filename, "w")
            newfile.puts "Outlier bounds are " + minOut.to_s + " and " + maxOut.to_s + "."
            newfile.puts "k = #{k}"
            @x_data.keys.each { |key|
                if (@x_data[key] > maxOut || @x_data[key] < minOut)
                    newfile.puts "#{key}"
                    @outlier_data[key] = 0 # Generate a hash with keys corresponding to outlier names
                end
            }
            newfile.close
        end # 1D Plotting

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
    # [+:outlierAnalysis+] Array to add outlier analysis lines. This array is of the form [ bool, k]. Bool turns on the analysis and k is the number of IQRs to use. Default is [false, 1] (off with 1 IQR).
    # [+:dataLabels+] Bool to include the key of the @x_data hash at the appropriate point of the plot. Default is false (off).
    # [+:addOutlierLabels+] Int to enable outlier labeling. Value represents the number of IQRs to consider when generating the list. Default is 0 (off). Must be > 0 to enable.
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
                     :outlierAnalysis => [false, 1],
                     :dataLabels => false,
                     :addOutlierLabels => 0 }

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
        addOutlierLabels = options[:addOutlierLabels]

        if (@plottype == :histogram)
            x = Array.new
            @x_data.keys.each { |key|
                x.push(@x_data[key].to_f)
            }


            bw = (max.to_f - min.to_f) / numBins.to_f
            x_count = Array.new
            x_axis = Array.new

            # checks which values belong in each bin. Edgecases go to the lower bin.
            (1..numBins).each {|n|
                count = 0
                x.each {|v|

                if(((min.to_f + (n.to_f-1) * bw.to_f) < (v.to_f)) and ((v.to_f) <= (min.to_f + n.to_f * bw.to_f)))
                    count = count + 1
                end
                }
                
                x_count.push(count)
            }
            if (min == x.min)
                x_count[0] = x_count[0] + 1 # Increments the first bin to account for the minimum value not being added in 
            end

            # To check bin counts
            binSum = 0;
            (0..(numBins-1)).each { |index|
                binSum = x_count[index] + binSum
                puts "Bin #{index} contains #{x_count[index]}"
                }
            puts "There were #{binSum} samples in the plot."

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
                    plot.arbitrary_lines << "set yrange [0:#{x_count.max + 1}]"

                    plot.data << Gnuplot::DataSet.new( [x_axis, x_count] ) do |ds|
                        ds.with = "boxes"
                        ds.notitle
                    end
                end
            end
        end

        if (@plottype == :scatter)
#            y = Array.new
 #           x = Array.new
  #          @x_data.keys.each { |key|
   #             x.push(x_data[key].to_f)
    #        }
     #       @y_data.keys.each { |key|
      #          y.push(y_data[key].to_f)
       #     }

            if(@x_data.length == @y_data.length)

            # generate a datafile to use in gnuplot
            datfile = filename + ".dat"

            newfile = File.new(datfile, "w")

            # pointCount tells how many points are on the graph
            pointCount = 0
            @x_data.keys.each { |i|
                newfile.puts "#{@x_data[i]}\t#{@y_data[i]}"
                pointCount = pointCount + 1
            }
            puts "There are #{pointCount} points on the plot."

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
                    if (outlierAnalysis[0])

                        # generate array of slopes of data
                        yDivX = Array.new
                        @x_data.keys.each { |key|
                            yDivX.push(@y_data[key].to_f / @x_data[key].to_f)
                        }

                        # apply the 5 number summary function
                        summData = Array.new
                        summData = yDivX.fiveNumSum # match to new function

                        # Calculate slopes of minimum and maximum lines to show outliers
                        maxline = summData[2] + outlierAnalysis[1] * (summData[3] - summData[1])
                        minline = summData[2] - outlierAnalysis[1] * (summData[3] - summData[1])

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
                    if (outlierAnalysis[0])
                        plotString = plotString + ", a(x) title 'Minimum', b(x) title 'Maximum'"
                    end
                    # add data point names if desired
                    if (dataLabels && addOutlierLabels = 0) # Won't label everything if outlier labeling is enabled
                        @x_data.keys.each { |key|
                            plot.arbitrary_lines << "set label '#{key}' at #{@x_data[key].to_f}, #{@y_data[key].to_f}"
                        }
                    end

                    # add outlier data labels
                    if ( addOutlierLabels > 0 )
                        self.findOutliers( filename + ".outlierdata", addOutlierLabels )
                        @outlier_data.keys.each { |key|
                            # add labels to each point where an outlier exists
                            plot.arbitrary_lines << "set label '#{key}' at #{@x_data[key].to_f}, #{@y_data[key].to_f}"
                        }
                        puts "Labeled #{@outlier_data.size} outliers."
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
    # [+:outlierAnalysis+] Array to add outlier analysis lines. This array is of the form [ bool, k]. Bool turns on the analysis and k is the number of IQRs to use. Default is [false, 1] (off with 1 IQR).
    # [+:dataLabels+] Bool to include the key of the @x_data hash at the appropriate point of the plot. Default is false (off).
    # [+:addOutlierLabels+] Int to enable outlier labeling. Value represents the number of IQRs to consider when generating the list. Default is 0 (off). Must be > 0 to enable.
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
                     :outlierAnalysis => [false, 1],
                     :dataLabels => false,
                     :addOutlierLabels => 0 }

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
        addOutlierLabels = options[:addOutlierLabels]

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
            
            if (min == x_array.min)
                x_count[0] = x_count[0] + 1 # Increments the first bin to account for the minimum value not being added in 
            end

            # To check bin counts
            binSum = 0;
            (0..(numBins - 1)).each { |index|
                binSum = x_count[index].to_i + binSum.to_i
                }
            puts "There were #{binSum} samples in the plot."


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
                    plot.arbitrary_lines << "set yrange [0:#{x_count.max + 1}]"

                    plot.data << Gnuplot::DataSet.new( [x_axis, x_count] ) do |ds|
                        ds.with = "boxes"
                        ds.notitle
                    end
                end
            end
        end

        if (@plottype == :scatter)

#            y = Array.new
 #           x = Array.new
  #          @x_data.keys.each { |key|
   #             x.push(x_data[key].to_f)
    #        }
     #       @y_data.keys.each { |key|
      #          y.push(y_data[key].to_f)
       #     }



            if(@x_data.length == @y_data.length)

                # generate a datafile to use in gnuplot
                datfile = filename + ".dat"

                newfile = File.new(datfile, "w")
                pointCount = 0
                @x_data.keys.each { |i|
                    newfile.puts "#{@x_data[i]}\t#{@y_data[i]}"
                    pointCount = pointCount + 1
                }
                puts "There are #{pointCount} points on the plot."
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
                        if (outlierAnalysis[0])

                            # generate array of slopes of data
                            yDivX = Array.new
                            @x_data.keys.each { |key|
                                yDivX.push(@y_data[key].to_f / @x_data[key].to_f)
                            }

                            # apply the 5 number summary function
                            summData = Array.new
                            summData = yDivX.fiveNumSum # match to new function

                            # Calculate slopes of minimum and maximum lines to show outliers
                            maxline = summData[2] + outlierAnalysis[1] * (summData[3] - summData[1])
                            minline = summData[2] - outlierAnalysis[1] * (summData[3] - summData[1])

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
                        if (outlierAnalysis[0])
                            plotString = plotString + ", a(x) title 'Minimum', b(x) title 'Maximum'"
                        end

                        # add data point names if desired
                        if (dataLabels && addOutlierLabels > 0) # Won't add labels to everything if we only want outliers labeled.
                            @x_data.keys.each { |key|
                            plot.arbitrary_lines << "set label '#{key}' at #{@x_data[key]}, #{@y_data[key]}"
                            }
                        end

                        # add outlier data labels
                        if ( addOutlierLabels > 0 )
                            self.findOutliers( filename + ".outlierdata", addOutlierLabels )
                            @outlier_data.keys.each { |key|
                                # add labels to each point where an outlier exists
                                plot.arbitrary_lines << "set label '#{key}' at #{@x_data[key].to_f}, #{@y_data[key].to_f}"
                            }
                        puts "Labeled #{@outlier_data.size} outliers."
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

