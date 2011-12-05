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
  # ==== Options
  #
  # [+:pvt+] The PVT used by this database.  Defaullt is +nil+.
  # [+:logfile+] The log file name.  nil disables logging.  Default is +nil+.
  # [+:mysqlhost+] The MySQL server host name.  Default is +localhost+.
  # [+:mysqlport+] The MySQL server port number.  Default is +3306+.
  # [+:mysqldb+] The MySQL database name.  Default is +LibertyFile+.  Do not change.
  # [+:mysqluser+] The MySQL username.  Default is +guest+.  Do not change.
  # [+:mysqlpass+] The MySQL password.  Default is +liberty+.  Do not change.
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
  # [+parameter+] The database parameter to query.  Must be the same as the database column (case sensitive).
  #
  # ==== Options
  #
  # [+:cells+] An array of cells to query.  +nil+ uses all cells.  Default is +nil+.
  # [+:footprint+] A single footprint to query.  +nil+ uses all footprints.  Default is +nil+.
  # [+:pvt+] The PVT corner to use.  Default is +this.pvt+.
  #
  # ==== Returns
  # [+results+] A Hash keyed by cell names.  The value of each entry is the value of +parameter+ for that cell.
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
  # [+:cells+] An array of cells to query.  +nil+ uses all cells.  Default is +nil+.
  # [+:footprint+] A single footprint to query.  +nil+ uses all footprints.  Default is +nil+.
  # [+:pvt+] The PVT corner to use.  Default is +this.pvt+.
  #
  # ==== Returns
  # [+results+] A Hash keyed by cell names.  The value of each entry is another Hash, keyed by "when" condition, containing leakage data.
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
    end #results.each
    query_string =  "SELECT #{LEAKAGE_WHEN_TABLE_NAME}.#{LEAKAGE_WHEN_VALUE_COLUMN},"
    query_string << "#{LEAKAGE_WHEN_TABLE_NAME}.#{LEAKAGE_WHEN_NAME_COLUMN},"
    query_string << "#{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN}\n"
    query_string << "FROM #{LEAKAGE_WHEN_TABLE_NAME}\n"
    query_string << "LEFT OUTER JOIN #{CELL_TABLE_NAME}\n"
    query_string << "ON #{CELL_TABLE_NAME}.#{CELL_TABLE_ID} = "
    query_string << "#{LEAKAGE_WHEN_TABLE_NAME}.#{LEAKAGE_WHEN_CELL_COLUMN}"
    if options[:cells] then
      query_string << "\nWHERE #{CELL_TABLE_NAME}.#{CELL_NAME_COLUMN} IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")"
    end
    query_string << ";"
    query(query_string) { |row|
      results[row[CELL_NAME_COLUMN]].store(row[LEAKAGE_WHEN_NAME_COLUMN],row[LEAKAGE_WHEN_VALUE_COLUMN].to_f)
    }

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
  # [+result+] An Array containing the names of all cell footprints as strings
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
  # [+cell+] The cell to query.
  #
  # ==== Returns
  # [+result+] The name of the given cell's footprint as a string
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
  # [+result+] An Array containing the names of all cells as strings
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

  def getCellsInFootprint( footprint )
    query_string =  "SELECT cells.name\n"
    query_string << "FROM cells LEFT OUTER JOIN footprints ON cells.cell_footprint = footprints.id\n"
    query_string << "WHERE footprints.name LIKE '#{footprint}';"
    results = Array.new
    query(query_string) { |row|
      results.push(row['name'])
    }
    results
  end #getCellsInFootprint

  # Perform a custom database query with logging
  #
  # ==== Parameters
  # [+string+] A string containing the SQL query terminated by a ';'
  # [+block+] The code block to process each row hash returned by the query.
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


  #
  # Query Max Capacitance values for output pins of all cells. If a cell has more than one output, add the max capacitance values.
  # Returns a hash with cell name associated with its total max capacitance value.
  #
  #
  def getOutputMaxCap
    querystr =  "SELECT cells.name AS cellname ,pins.max_capacitance\n"
    querystr << "FROM pins LEFT OUTER JOIN cells ON cells.id = pins.cell_id\n"
    querystr << "WHERE pins.direction = 'output' AND cells.cell_footprint = 105;"
    results = Hash.new
    query( querystr ) { |row|
        if results.has_key?(row["cellname"]) then
            results[row["cellname"]] += row["max_capacitance"].to_f
        else
            results.store(row["cellname"],row["max_capacitance"].to_f)
        end
    }
    results
  end #getOutputMaxCap

  def getTimingData(options = {})
    defaults = { :cells => nil,
                 :footprint => nil,
                 :pvt => @pvt }
    options = defaults.merge(options)
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end
    #select sum(value)/count(value) from timing_data left outer join timing on timing.id = timing_data.timing_id left outer join pins on pins.id = timing.pin_id left outer join cells on pins.cell_id = cells.id where cells.name LIKE 'INVM1S' group by pin_id;
    query_string =  "SELECT sum(timing_data.value)/count(timing_data.value) AS avg,\n"
    query_string << "       min(timing_data.value) AS min,\n"
    query_string << "       max(timing_data.value) AS max,\n"
    query_string << "       timing.timing_type,\n"
    query_string << "       timing.when AS when_cond,\n"
    query_string << "       pins.name AS pin_name,\n"
    query_string << "       cells.name AS cell_name\n"
    query_string << "FROM timing_data LEFT OUTER JOIN timing ON timing.id = timing_data.timing_id\n"
    query_string << "                 LEFT OUTER JOIN pins ON pins.id = timing.pin_id\n"
    query_string << "                 LEFT OUTER JOIN cells ON cells.id = pins.cell_id\n"
    if options[:cells] then
      query_string << "WHERE cells.name IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")"
    end
    query_string << "\nGROUP BY timing.id;"
    results = Hash.new
    query(query_string) { |row|
      key = "#{row['cell_name']}.#{row['pin_name']}.#{row['when_cond'] || "null"}.#{row['timing_type']}"
      results.store(key,Hash.new)
      results[key].store('min',row['min'].to_f)
      results[key].store('max',row['max'].to_f)
      results[key].store('avg',row['avg'].to_f)
    }

    results
  end #getTimingData

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

