#!/usr/bin/ruby -w0
# LibertyDatabase.rb
# 2011-11-10
# John Wright
# jcwr@cypress.com
#

require 'rubygems'
require 'mysql'

class LibertyDatabase
  attr_reader :pvt, :db

  def initialize( options = {} )
    defaults = { :process => "tt",
                 :voltage => "1.8",
                 :temperature => "25",
                 :mysqlhost => "localhost",
                 :mysqlport => 3306,
                 :mysqldb => "LibertyFile",
                 :mysqluser => "guest",
                 :mysqlpass => "liberty" }
    options = defaults.merge(options)

    @pvt = { :process => options[:process],
             :voltage => options[:voltage],
             :temperature => options[:temperature] }

    begin #catching Mysql::Error
      @db = Mysql.real_connect( options[:mysqlhost],
                                options[:mysqluser],
                                options[:mysqlpass],
                                options[:mysqldb],
                                options[:mysqlport] )
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

  def close
    @db.close if @db
  end #close

end #LibertyFile

