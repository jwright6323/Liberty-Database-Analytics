#!/usr/bin/ruby -w0
# LibertyDatabase.rb
# 2011-11-10
# John Wright, Daniel Peters, Edward Poore
# jcwr@cypress.com, danmanstx@gmail.com, edward.poore@gmail.com
#

require 'rubygems'
require 'mysql'

# LibertyDatabase is a class to connect to and query a MySQL database containing Liberty file data
class LibertyDatabase
  attr_reader :pvt, :db, :logfile

  CELL_TABLE_NAME = "cells"
  CELL_TABLE_ID = "id"
  CELL_LEAKAGE_COLUMN = "cell_leakage_power"
  CELL_FOOTPRINT_COLUMN = "cell_footprint"
  CELL_NAME_COLUMN = "name"
  FOOTPRINT_TABLE_NAME = "footprints"
  FOOTPRINT_TABLE_ID = "id"
  FOOTPRINT_NAME_COLUMN = "name"
  LEAKAGE_WHEN_TABLE_NAME = "leakage_power"
  LEAKAGE_WHEN_CELL_COLUMN = "cell_id"
  LEAKAGE_WHEN_VALUE_COLUMN = "value"
  LEAKAGE_WHEN_NAME_COLUMN = "when"

  # Constructor
  #
  # ==== Parameters
  #
  # * +:pvt+ - The PVT used by this database.  Defaullt is +nil+.
  # * +:logfile+ - The log file name.  nil disables logging.  Default is +nil+.
  # * +:mysqlhost+ - The MySQL server host name.  Default is +localhost+.
  # * +:mysqlport+ - The MySQL server port number.  Default is +3306+.
  # * +:mysqldb+ - The MySQL database name.  Default is +LibertyFile+.  Do not change.
  # * +:mysqluser+ - The MySQL username.  Default is +guest+.  Do not change.
  # * +:mysqlpass+ - The MySQL password.  Default is +liberty+.  Do not change.
  #
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

  # Retrieve data from the SQL database
  #
  # ==== Parameters
  # * +parameter+ - The database parameter to query.  Must be the same as the database column (case sensitive).
  #
  # ==== Options
  #
  # * +:cells+ - An array of cells to query.  +nil+ uses all cells.  Default is +nil+.
  # * +:footprint+ - A single footprint to query.  +nil+ uses all footprints.  Default is +nil+.
  # * +:pvt+ - The PVT corner to use.  Default is +this.pvt+.
  #
  # ==== Returns
  # * +results+ - A Hash keyed by cell names.  The value of each entry is the value of +parameter+ for that cell.
  #
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

  # Retrieve leakage data with "when" conditions
  #
  # ==== Options
  #
  # * +:cells+ - An array of cells to query.  +nil+ uses all cells.  Default is +nil+.
  # * +:footprint+ - A single footprint to query.  +nil+ uses all footprints.  Default is +nil+.
  # * +:pvt+ - The PVT corner to use.  Default is +this.pvt+.
  #
  # ==== Returns
  # * +results+ - A Hash keyed by cell names.  The value of each entry is another Hash, keyed by "when" condition, containing leakage data.
  #
  def getLeakage( options={} )
    defaults = { :cells => nil,
                 :footprint => nil,
                 :pvt => @pvt }
    options = defaults.merge(options)

    results = getData(CELL_LEAKAGE_COLUMN,options)
    results.each do |key,val|
      results.delete(key)
      results.store(key,Hash.new)
      results[key].store(:wc,val.to_f)
      query_string =  "SELECT #{LEAKAGE_WHEN_TABLE_NAME}.#{LEAKAGE_WHEN_VALUE_COLUMN},"
      query_string << "#{LEAKAGE_WHEN_TABLE_NAME}.#{LEAKAGE_WHEN_NAME_COLUMN}\n"
      query_string << "FROM #{LEAKAGE_WHEN_TABLE_NAME}\n"
      query_string << "LEFT OUTER JOIN #{CELL_TABLE_NAME}\n"
      query_string << "ON #{CELL_TABLE_NAME}.#{CELL_TABLE_ID} = "
      query_string << "#{LEAKAGE_WHEN_TABLE_NAME}.#{LEAKAGE_WHEN_CELL_COLUMN}\n"
      query_string << "WHERE #{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN} = '#{key}';"
      query(query_string) { |row|
        results[key].store(row[LEAKAGE_WHEN_NAME_COLUMN],row[LEAKAGE_WHEN_VALUE_COLUMN].to_f)
      }
    end #results.each

    results
  end #getWhenData

  # Get the current PVT corner (Not Implemented)
  #
  # ==== Returns
  # * +nil+
  #
  def getPVT
    #TODO
    nil
  end #getPVTs

  # Get an array of all cell footprints
  #
  # ==== Returns
  # * +result+ - An Array containing the names of all cell footprints as strings
  #
  def getFootprints
    query_string =  "SELECT #{FOOTPRINT_TABLE_NAME}.#{FOOTPRINT_NAME_COLUMN}\n"
    query_string << "FROM #{FOOTPRINT_TABLE_NAME}\n;"
    result = Array.new
    query(query_string) { |row|
      result.push(row["name"])
    }

    result
  end #getFootprints

  # Get the footprint of a single cell
  #
  # ==== Parameters
  # * +cell+ - The cell to query.
  #
  # ==== Returns
  # * +result+ - The name of the given cell's footprint as a string
  #
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

  # Get all cells in the database
  #
  # ==== Returns
  # * +result+ - An Array containing the names of all cells as strings
  #
  def getCells
    query_string =  "SELECT #{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN}\n"
    query_string << "FROM #{CELL_TABLE_NAME};"
    results = Array.new
    query(query_string) { |row|
      results.push( row[CELL_NAME_COLUMN] )
    }

    results
  end #getCells

  # Perform a custom database query with logging
  #
  # ==== Parameters
  # * +string+ - A string containing the SQL query terminated by a ';'
  # * +block+ - The code block to process each row hash returned by the query.
  #
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

  # Close the database and logfile
  def close
    @db.close if @db
    log "Database closed"
    @logfile.close if @logfile
  end #close

  private

  # Log an error to the logfile and stderr
  def errlog( str )
    $stderr.puts str
    @logfile.puts str if @logfile
  end #errlog

  # Log to the logfile and stdout if in verbose mode
  def log( str )
    $stdout.puts str if $verbose
    @logfile.puts str if @logfile
  end #log

end #LibertyFile

