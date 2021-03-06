#!/usr/bin/ruby -w0
# LibertyDatabase.rb
# 2011-11-10
# John Wright, Daniel Peters, Edward Poore
# jcwr@cypress.com, danmanstx@gmail.com, edward.poore@gmail.com
#

#require 'rubygems'
require 'mysql.rb'

# LibertyDatabase is a class to connect to and query a MySQL database containing Liberty file data
class LibertyDatabase
  attr_reader :pvt, :db, :logfile

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
        query_string = "SELECT * FROM pvt WHERE id = 1;"
        query ( query_string ) { |row|
          @pvt = Array.[](row["process"].to_i,row["nom_voltage"].to_f,row["nom_temperature"].to_f)
        }
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
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end

    #build the SQL query
    query_string =  "SELECT cells.#{parameter},cells.name\n"
    query_string << "FROM cells"
    if options[:footprint] then
      query_string << "\nLEFT OUTER JOIN footprints\n"
      query_string << "ON footprints.id = cells.cell_footprint\n"
      query_string << "WHERE footprints.name "
      query_string << "= '#{options[:footprint]}'"
      if options[:cells] || options[:pvt] then
        query_string << "\nAND "
      end
    elsif options[:cells] || options[:pvt] then
      query_string << "\nWHERE "
    end
    if options[:cells] then
      query_string << "cells.name IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")"
      if options[:pvt] then
        query_string << "\nAND"
      end
    end
    if options[:pvt] then
      query_string << " cells.pvt_id = #{getPVTid( options[:pvt] )};"
    end
    results = Hash.new
    query(query_string) { |row|
      results.store( row["name"], row[parameter] )
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
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end

    results = getData("cell_leakage_power",options)
    results.each do |key,val|
      results.delete(key)
      results.store(key,Hash.new)
      results[key].store(:wc,val.to_f)
    end #results.each
    query_string =  "SELECT leakage_power.when,leakage_power.value,cells.name\n"
    query_string << "FROM leakage_power\n"
    query_string << "LEFT OUTER JOIN cells ON cells.id = leakage_power.cell_id"
    if options[:cells] then
      query_string << "\nWHERE cells.name IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")"
    end
    query_string << "\nAND cells.pvt_id = #{getPVTid( options[:pvt] )};"
    query(query_string) { |row|
      results[row["name"]].store(row["when"],row["value"].to_f)
    }

    results
  end #getLeakage

  # Get the current PVT corner
  #
  # ==== Returns
  # [+pvt+] The PVT array [process,voltage,temperature]
  #
  def getPVT
    @pvt
  end #getPVT

  # Set the current PVT corner
  #
  # ==== Parameters
  # [+p+] The process (always 1 at the moment)
  # [+v+] The Voltage (float)
  # [+t+] The temperature in C (float)
  #
  def setPVT( p, v, t)
    @pvt = Array.[](p,v,t)
  end #setPVT

  # Get an array of all cell footprints
  #
  # ==== Returns
  # [+result+] An Array containing the names of all cell footprints as strings
  #
  def getFootprints
    query_string =  "SELECT footprints.name\n"
    query_string << "FROM footprints\n;"
    result = Array.new
    query(query_string) { |row|
      result.push(row["name"])
    }

  end #getFootprints

  # Get the footprint of a single cell
  #
  # ==== Parameters
  # [+cell+] The cell to query
  #
  # ==== Returns
  # [+result+] The name of the given cell's footprint as a string
  #
  def getCellFootprint( cell )
    query_string =  "SELECT footprints.name\n"
    query_string << "FROM cells LEFT OUTER JOIN footprins\n"
    query_string << "ON cells.cell_footprint = footprints.id\n"
    query_string << "WHERE  "
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
    query_string =  "SELECT cells.name\n"
    query_string << "FROM cells;"
    results = Array.new
    query(query_string) { |row|
      results.push( row["name"] ) unless results.include?( row["name"] )
    }

    results
  end #getCells

  # Get all of the cells with a given footprint
  #
  # ==== Parameters
  # [+footprint+] The footprint to query
  #
  # ==== Returns
  # [+results+] An Array containing the cell names in the specified footprint
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

  # Query Max Capacitance values for output pins of all cells. If a cell has more than one output, add the max capacitance values
  #
  # ==== Options
  #
  # [+:cells+] An array of cells to query.  +nil+ uses all cells.  Default is +nil+.
  # [+:footprint+] A single footprint to query.  +nil+ uses all footprints.  Default is +nil+.
  # [+:pvt+] The PVT corner to use.  Default is +this.pvt+.
  #
  # ==== Returns
  # [+result+] A Hash with cell names as keys and sum of pin max capacitance as a value
  #
  def getOutputMaxCap(options={})
    defaults = { :cells => nil,
                 :footprint => nil,
                 :pvt => @pvt }
    options = defaults.merge(options)
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end
    querystr =  "SELECT cells.name AS cellname, pins.max_capacitance\n"
    querystr << "FROM pins LEFT OUTER JOIN cells ON cells.id = pins.cell_id\n"
    querystr << "WHERE pins.direction = 'output'"
    if options[:cells] then
      querystr << " AND cells.name IN ("
      options[:cells].each { |cell|
        querystr << "'#{cell}',"
      }
      querystr.chomp!(',')
      querystr << ")"
    end
    query_string << "\nAND cells.pvt_id = #{getPVTid(options[:pvt])};"
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

  # Query timing data for cells or cell footprints
  #
  # ==== Options
  #
  # [+:cells+] An array of cells to query.  +nil+ uses all cells.  Default is +nil+.
  # [+:footprint+] A single footprint to query.  +nil+ uses all footprints.  Default is +nil+.
  # [+:type+] Best Case (:bc), Worst Case (:wc), or Average (:avg), default is :wc
  # [+:pvt+] The PVT corner to use.  Default is +this.pvt+.
  #
  # ==== Returns
  # [+results+] A Hash with keys of the format cell_name.pin_name.timing_type[when], values are Hashes with keys of min,max,avg
  #
  def getTimingData(options = {})
    defaults = { :cells => nil,
                 :footprint => nil,
                 :type => :wc,
                 :pvt => @pvt }
    options = defaults.merge(options)
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end
    query_string =  "SELECT max(timing_data.value) AS val,\n"
    query_string =  "SELECT sum(timing_data.value)/count(timing_data.value) AS val,\n" if options[:type] == :avg
    query_string =  "SELECT min(timing_data.value) AS val,\n" if options[:type] == :bc
    query_string << "       timing.timing_type,\n"
    query_string << "       timing.when AS when_cond,\n"
    query_string << "       pins.name AS pin_name,\n"
    query_string << "       cells.name AS cell_name\n"
    query_string << "FROM timing_data LEFT OUTER JOIN timing ON timing.id = timing_data.timing_id\n"
    query_string << "                 LEFT OUTER JOIN pins ON pins.id = timing.pin_id\n"
    query_string << "                 LEFT OUTER JOIN cells ON cells.id = pins.cell_id\n"
    query_string << "WHERE "
    if options[:cells] then
      query_string << "cells.name IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")\n AND "
    end
    query_string << "cells.pvt_id = #{getPVTid(options[:pvt])}\n"
    query_string << "GROUP BY timing.id;"
    results = Hash.new
    query(query_string) { |row|
      key = "#{row['cell_name']}.#{row['pin_name']}.#{row['timing_type']}"
      whenval = row['when_cond'] || "null"
      unless results[key]
        results.store(key,Hash.new)
      end
      results[key].store(whenval,row["val"].to_f)
    }

    results
  end #getTimingData

  def getAllPowerData(options = {})
    defaults = { :cells => nil,
                 :footprint => nil,
                 :pvt => @pvt }
    options = defaults.merge(options)
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end
    query_string =  "SELECT internal_power_data.value AS val,\n"
    query_string << "       internal_power_data.index_1 AS cap,\n"
    query_string << "       internal_power_data.index_2 AS slew,\n"
    query_string << "       internal_power.when AS when_cond,\n"
    query_string << "       pins.name AS pin_name,\n"
    query_string << "       cells.name AS cell_name\n"
    query_string << "FROM internal_power_data LEFT OUTER JOIN internal_power ON internal_power.id = internal_power_data.internal_power_id\n"
    query_string << "                 LEFT OUTER JOIN pins ON pins.id = internal_power.pin_id\n"
    query_string << "                 LEFT OUTER JOIN cells ON cells.id = pins.cell_id\n"
    query_string << "WHERE "
    if options[:cells] then
      query_string << "cells.name IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")\n AND "
    end
    query_string << "cells.pvt_id = #{getPVTid(options[:pvt])};"
    results = Hash.new
    query(query_string) { |row|
      key = "#{row['cell_name']}.#{row['pin_name']}"
      whenval = row['when_cond'].to_s
      cap = row['cap'].to_s
      slew = row['slew'].to_s
      unless results.has_key?(key)
        results.store(key,Hash.new)
      end
      unless results[key].has_key?(whenval)
        results[key].store(whenval,Hash.new)
      end
      unless results[key][whenval].has_key?(slew)
        results[key][whenval].store(cap,Hash.new)
      end
      results[key][whenval][cap].store(slew,row['val'])
    }

    results
  end #getPowerData


  def getPowerData(options = {})
    defaults = { :cells => nil,
                 :footprint => nil,
                 :type => :wc,
                 :pvt => @pvt }
    options = defaults.merge(options)
    if options[:footprint] then
      options[:cells] = getCellsInFootprint(options[:footprint])
    end
    query_string =  "SELECT max(internal_power_data.value) AS val,\n"
    query_string =  "SELECT sum(internal_power_data.value)/count(internal_power_data.value) AS val,\n" if options[:type] == :avg
    query_string =  "SELECT min(internal_power_data.value) AS val,\n" if options[:type] == :bc
    query_string << "       internal_power.when AS when_cond,\n"
    query_string << "       pins.name AS pin_name,\n"
    query_string << "       cells.name AS cell_name\n"
    query_string << "FROM internal_power_data LEFT OUTER JOIN internal_power ON internal_power.id = internal_power_data.internal_power_id\n"
    query_string << "                 LEFT OUTER JOIN pins ON pins.id = internal_power.pin_id\n"
    query_string << "                 LEFT OUTER JOIN cells ON cells.id = pins.cell_id\n"
    query_string << "WHERE "
    if options[:cells] then
      query_string << "cells.name IN ("
      options[:cells].each { |cell|
        query_string << "'#{cell}',"
      }
      query_string.chomp!(',')
      query_string << ")\n AND "
    end
    query_string << "cells.pvt_id = #{getPVTid(options[:pvt])}\n"
    query_string << "GROUP BY internal_power.id;"
    results = Hash.new
    query(query_string) { |row|
      key = "#{row['cell_name']}.#{row['pin_name']}.#{row['internal_power_type']}"
      whenval = row['when_cond'] || "null"
      unless results[key]
        results.store(key,Hash.new)
      end
      results[key].store(whenval,row["val"].to_f)
    }

    results
  end #getPowerData

  # Close the database and logfile
  def close
    @db.close if @db
    log "Database closed"
    @logfile.close if @logfile
  end #close

  private

  def getPVTid( pvt )
    query_string =  "SELECT pvt.id FROM pvt\n"
    # Use < and > beacuse = in floating point is unreliable
    if pvt[1] > 0 then
      query_string << "WHERE pvt.nom_voltage < #{pvt[1]*1.001}\n"
      query_string << "  AND pvt.nom_voltage > #{pvt[1]*0.999}\n"
    else
      query_string << "WHERE pvt.nom_voltage < #{pvt[1]*0.999}\n"
      query_string << "  AND pvt.nom_voltage > #{pvt[1]*1.001}\n"
    end
    if pvt[2] > 0 then
      query_string << "  AND pvt.nom_temperature < #{pvt[2]*1.001}\n"
      query_string << "  AND pvt.nom_temperature > #{pvt[2]*0.999};"
    else
      query_string << "  AND pvt.nom_temperature < #{pvt[2]*0.999}\n"
      query_string << "  AND pvt.nom_temperature > #{pvt[2]*1.001};"
    end
    results = nil
    query ( query_string ) { |row|
      results = row["id"].to_i
    }
    results || 0
  end #getPVTid

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

