#!/usr/bin/env ruby
# basic test to use gnuplot in ruby
# plots a curve as defined by x and y

require 'rubygems'
require 'gnuplot'

def plot(x, y, x_label, y_label, title)
  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
      plot.title   title
      plot.ylabel  y_label
      plot.xlabel  x_label

      plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
        ds.with = "points"
        ds.notitle
      end
    end
  end
end
