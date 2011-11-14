#!/usr/bin/ruby -w0
# LibertyDatabase.rb
# 2011-11-10
# John Wright, Daniel Peters, Edward Poore
# jcwr@cypress.com, danmanstx@gmail.com, edward.poore@gmail.com
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
  attr_reader :pvt, :db, :logfile

  def initialize( options = {} )
    defaults = { :pvt => nil,
                 :logfile => nil,
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

    begin #catchiing File::IOError
      if options[:logfile] then
        @logfile = File.open(options[:logfile],"a+")
      else
        @logfile = nil
      end
    rescue File::IOError => e
      @logfile = nil
      errlog "Error opening log file. :logfile => '#{options[:logfile]}'"
    end #catching File::IOError

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
      log "Connected to mysql database successfully.  Info:"
      log "  host : #{options[:mysqlhost]}"
      log "  port : #{options[:mysqlport]}"
      log "  user : #{options[:mysqluser]}"
      log "  pass : #{options[:mysqlpass]}"
      log "  db   : #{options[:mysqldb]}"
    rescue Mysql::Error => e
      @db = nil
      errlog "Error connecting to mysql database.  Debug info:"
      errlog "  host : #{options[:mysqlhost]}"
      errlog "  port : #{options[:mysqlport]}"
      errlog "  user : #{options[:mysqluser]}"
      errlog "  pass : #{options[:mysqlpass]}"
      errlog "  db   : #{options[:mysqldb]}"
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
    query_string << "FROM #{CELL_TABLE_NAME}"
    if options[:footprint] then
      query_string << "\nLEFT OUTER JOIN #{FOOTPRINT_TABLE_NAME}\n"
      query_string << "ON #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_TABLE_ID} "
      query_string << "= #{CELL_TABLE_NAME}.#{CELL_FOOTPRINT_COLUMN}\n"
      query_string << "WHERE #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_NAME_COLUMN} "
      query_string << "= '#{options[:footprint]}'"
      if options[:cells] then
        query_string << "\nAND "
      end
    elsif options[:cells] then
      query_string << "\nWHERE "
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
    results = Hash.new
    query(query_string) { |row|
      results.store( row[CELL_NAME_COLUMN], row[parameter] )
    }

    results
  end #getData

  def getPVTs
    #TODO
    nil
  end #getPVTs

  def getFootprints
    query_string =  "SELECT #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_NAME_COLUMN}\n"
    query_string << "FROM #{FOOTPRINT_TABLE_NAME}\n;"
    result = Array.new
    query(query_string) { |row|
      result.push(row["name"])
    }

    result
  end #getFootprints

  def getCellFootprint( cell )
    query_string =  "SELECT #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_NAME_COLUMN}\n"
    query_string << "FROM #{CELL_TABLE_NAME} LEFT OUTER JOIN #{FOOTPRINT_TABLE_NAME}\n"
    query_string << "ON #{CELL_TABLE_NAME}.#{CELL_FOOTPRINT_COLUMN} = "
    query_string << "#{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_TABLE_ID}\n"
    query_string << "WHERE #{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN} "
    query_string << "= '#{cell}';"
    result = nil
    query(query_string) { |row|
      result = row["name"]
    }

    result
  end #getCellFootprint

  def getCells
    query_string =  "SELECT #{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN}\n"
    query_string << "FROM #{CELL_TABLE_NAME};"
    results = Array.new
    query(query_string) { |row|
      results.push( row[CELL_NAME_COLUMN] )
    }

    results
  end #getCells

  def query( string, &block )
    begin #catching Mysql::Error
      @db.query(string).each_hash { |row|
        yield row
      }
      log "Query completed successfully:"
      log string.gsub(/^/,"  ")
    rescue Mysql::Error => e
      errlog "Error executing database query.  Debug info:"
      errlog string.gsub(/^/,"  ")
    end #catching Mysql::Error
  end #query

  def close
    @db.close if @db
    log "Database closed"
    @logfile.close if @logfile
  end #close

  def errlog( str )
    $stderr.puts str
    @logfile.puts str if @logfile
  end #errlog

  def log( str )
    $stdout.puts str if $verbose
    @logfile.puts str if @logfile
  end #log

end #LibertyFile

