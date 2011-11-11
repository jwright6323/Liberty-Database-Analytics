#!/usr/bin/ruby -w0
# LibertyDatabase.rb
# 2011-11-10
# John Wright
# jcwr@cypress.com
#

require 'rubygems'
require 'mysql'

## Schema info ##
CELL_TABLE_NAME = "cells"
CELL_TABLE_ID = "id"
CELL_FOOTPRINT_COLUMN = "cell_footprint"
CELL_NAME_COLUMN = "name"
FOOTPRINT_TABLE_NAME = "footprints"
FOOTPRINT_TABLE_ID = "id"
FOOTPRINT_NAME_COLUMN = "name"

class LibertyDatabase
  attr_reader :pvt, :db

  def initialize( options = {} )
    defaults = { :pvt => nil,
                 :mysqlhost => "localhost",
                 :mysqlport => 3306,
                 :mysqldb => "LibertyFile",
                 :mysqluser => "guest",
                 :mysqlpass => "liberty" }
    options = defaults.merge(options)

    if options[:pvt]
      @pvt = options[:pvt]
    else
      @pvt = nil
    end

    begin #catching Mysql::Error
      @db = Mysql.real_connect( options[:mysqlhost],
                                options[:mysqluser],
                                options[:mysqlpass],
                                options[:mysqldb],
                                options[:mysqlport] )
      unless @pvt #is defined
        #query for a default
        #TODO
      end
    rescue Mysql::Error => e
      @db = nil
      $stderr.puts "Error connecting to mysql database.  Debug info:"
      $stderr.puts "  host : #{options[:mysqlhost]}"
      $stderr.puts "  port : #{options[:mysqlport]}"
      $stderr.puts "  user : #{options[:mysqluser]}"
      $stderr.puts "  pass : #{options[:mysqlpass]}"
      $stderr.puts "  db   : #{options[:mysqldb]}"
    end #catching Mysql::Error

  end #initialize

  def getData( parameter, options={} )
    defaults = { :cells => nil,
                 :footprint => nil,
                 :pvt => @pvt }
    options = defaults.merge(options)

    #build the SQL query
    query_string =  "SELECT #{CELL_TABLE_NAME}.#{parameter},"
    query_string << "#{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN}\n"
    query_string << "FROM #{CELL_TABLE_NAME}\n"
    if options[:footprint] then
      query_string << "LEFT OUTER JOIN #{FOOTPRINT_TABLE_NAME}\n"
      query_string << "ON #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_TABLE_ID} "
      query_string << "= #{CELL_TABLE_NAME}.#{CELL_FOOTPRINT_COLUMN}\n"
      query_string << "WHERE #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_NAME_COLUMN} "
      query_string << "LIKE '#{options[:footprint]}'"
      if options[:cells] then
        query_string << "\nAND "
      end
    elsif options[:cells] then
      query_string << "WHERE "
    end
    if options[:cells] then
      query_string << "#{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN} IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")"
    end
    query_string << ";"
    puts query_string
    results = Hash.new
    begin #catching Mysql::Error
      @db.query(query_string).each_hash { |row|
        results.store( row[CELL_NAME_COLUMN], row[parameter] )
      }
      if options[:cells] then
        #extract only the cells of interest
        #TODO
      else
        #TODO
      end
    rescue Mysql::Error => e
      $stderr.puts "Error executing database query.  Debug info:"
      $stderr.puts query_string.gsub(/^/,"  ")
    end #catching Mysql::Error

    results
  end #query

  def close
    @db.close if @db
  end #close

end #LibertyFile

