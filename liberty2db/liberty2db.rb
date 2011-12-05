#!/usr/bin/ruby -w
# liberty to MySQL
require "mysql"

def store_values_db(id, table_type, name,index_1,index_2,values)
	count = 0
	#puts index_2[0]
	result = $dbh.query("SELECT id FROM `lut_templates` where template_name='#{name}'")
	if result.num_rows == 0
		template_id = insert_db("lut_templates", "template_name",name)
	else
		template_id = result.fetch_row[0]	
	end	

	result = $dbh.query("SELECT id FROM `lut_types` where type_name='#{table_type}'")
	if result.num_rows == 0
		type_id = insert_db("lut_types", "type_name",table_type)
	else
		type_id = result.fetch_row[0]	
	end	
	#puts "IN STORE VALUES"
	index_1.each do |i1|
		#puts "GOING" 
		index_2.each do |i2|

			#puts "STORE: " + i1 + " " + i2 + " " + values[count]
			#puts "Hello #{i2}"
			$dbh.query("INSERT INTO `#{$lut_type}_data` SET `#{$lut_type}_id`='#{$power_timing_id}',`lut_type_id`='#{type_id}',`lut_template_id`='#{template_id}',`index_1`=#{i1},`index_2`=#{i2},`value`='#{values[count]}'")		
			count +=1
		end
	end
end


def store_pairs(table,line,where_name,where_value)
	if line=~/(.+)\s*:\s*(.*);/
	name = $1.strip
	value = $2.strip.gsub("\"","")
		if name == "cell_footprint"
			puts "Footprint: #{value}"
			result = $dbh.query("SELECT * FROM `footprints` where name='#{value}'")
			if result.num_rows == 0
				id = insert_db("footprints", "name",value)
				update_db(table, "cell_footprint",id,"name",$section_name) 
			else	
			result.each_hash do |row|
			update_db(table, "cell_footprint",row['id'],"name",$section_name) 
			end
			end
		else
			update_db(table, name,value,where_name,where_value)
		end
	end

end
def update_db(table,name,value,where_name,where_value)
	puts "Update TABLE: #{table} FIELD: #{name} VALUE: #{value} WHERE NAME: #{where_name} = VALUE: #{where_value}"
	result = $dbh.query("SHOW COLUMNS FROM `#{table}` LIKE '#{name}'")
	if result.num_rows  == 0
		puts "Column #{name} doesn't exist"
	else 
		$dbh.query("UPDATE #{table} SET `#{name}`=\"#{value}\" WHERE `#{where_name}`='#{where_value}'")
	end
end 
def insert_db(table, name,value)
	 #last generated AUTO_INCREMENT VALUE
	id = 0
	puts "Insert row in TABLE: #{table} FIELD: #{name} VALUE: #{value}"
	result = $dbh.query("SHOW COLUMNS FROM `#{table}` LIKE '#{name}'")
	if result.num_rows  == 0
		puts "Column #{name} doesn't exist"
	else 
		#INSERT IGNORE: http://dev.mysql.com/doc/refman/5.0/en/constraint-primary-key.html
		$dbh.query("INSERT IGNORE INTO #{table} (#{name}) VALUES ('#{value}')")
		id = $dbh.insert_id()
	end
	return id
end

if ARGV.length == 0
        puts "liberty2db.rb [libertyfile]"
        exit
else
        filename = ARGV[0]
end

begin
# connect to the MySQL server
#CHANGE THE DATABASE NAME 
#TODO: Create database if doesn't exist
database_name = "LibertyFile"
$dbh = Mysql.real_connect("localhost", "root", "")
     # get server version string and display it
puts "Server version: " + $dbh.get_server_info

$dbh.query("CREATE DATABASE IF NOT EXISTS #{database_name}")
$dbh.query("USE #{database_name}")
$dbh.query("DROP TABLE IF EXISTS cells")
  $dbh.query("CREATE TABLE  `#{database_name}`.`cells` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20)  DEFAULT NULL,
  `area` float DEFAULT NULL,
  `dont_touch` ENUM('true','false') DEFAULT NULL,
  `dont_use` ENUM('true','false') DEFAULT NULL,
  `cell_footprint` int(10) unsigned DEFAULT NULL,
  `PVT_id` int(11) DEFAULT NULL,
  `cell_leakage_power` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS pins")
$dbh.query("CREATE TABLE  `#{database_name}`.`pins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cell_id` int(11) DEFAULT NULL,
  `name` varchar(20) DEFAULT NULL,
  `direction` ENUM('output','input') DEFAULT NULL,
  `fall_capacitance` float DEFAULT NULL,
  `capacitance` float DEFAULT NULL,
  `rise_capacitance` float DEFAULT NULL,
  `max_transition` float DEFAULT NULL,
  `power_down_function` varchar(20) DEFAULT NULL,
  `function` varchar(20) DEFAULT NULL,
  `max_capacitance` float DEFAULT NULL,
  `internal_power` int(11) DEFAULT NULL,
  `timing` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS footprints")
$dbh.query("CREATE TABLE  `#{database_name}`.`footprints` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`) 
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS leakage_power")
$dbh.query("CREATE TABLE  `#{database_name}`.`leakage_power` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `cell_id` int(11) DEFAULT NULL,
  `when` varchar(50) DEFAULT NULL,
  `value` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS internal_power")
$dbh.query("CREATE TABLE  `#{database_name}`.`internal_power` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `pin_id` int(11) DEFAULT NULL, 
  `related_pin` varchar(5) DEFAULT NULL,
  `when` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS internal_power_data")
$dbh.query("CREATE TABLE  `#{database_name}`.`internal_power_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `internal_power_id` int(11) DEFAULT NULL,
  `lut_type_id` int(11) DEFAULT NULL, 
  `lut_template_id` int(11) DEFAULT NULL, 
  `index_1` float DEFAULT NULL,
  `index_2` float DEFAULT NULL,  
  `value` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS timing")
$dbh.query("CREATE TABLE  `#{database_name}`.`timing` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `pin_id` int(11) DEFAULT NULL, 
  `related_pin` varchar(5) DEFAULT NULL,
  `sdf_cond` varchar(50) DEFAULT NULL,
  `timing_sense` varchar(50) DEFAULT NULL,
  `timing_type` varchar(50) DEFAULT NULL,
  `when` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS timing_data")
$dbh.query("CREATE TABLE  `#{database_name}`.`timing_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `timing_id` int(11) DEFAULT NULL,
  `lut_type_id` int(11) DEFAULT NULL, 
  `lut_template_id` int(11) DEFAULT NULL, 
  `index_1` float DEFAULT NULL,
  `index_2` float DEFAULT NULL,  
  `value` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS lut_templates")
$dbh.query("CREATE TABLE  `#{database_name}`.`lut_templates` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `template_name` varchar(50) DEFAULT NULL, 
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")
$dbh.query("DROP TABLE IF EXISTS lut_types")
$dbh.query("CREATE TABLE  `#{database_name}`.`lut_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT, 
  `type_name` varchar(50) DEFAULT NULL, 
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
")

$pin_id = ""
$cell = ""
section = ""
$section_name = ""
$lut_type = ""
$power_timing_id = ""
$leakage_id = ""
$index_2_array = Array[""]
f = File.open(filename,"r")
f.each do |line|
	cell_id = 0
	#puts line
	line = line.strip  #remove beginning and end white space

	if line=~/^(\w+)\s*\(([\"\w]*)\)/
		section = $1.to_sym 
		$section_name = $2.gsub("\"","")
		#puts "#{section} #{$section_name}"
	end

	if line=~/^cell\s*\((.*)\)/
		$cell_id = insert_db("cells","name",$section_name)
	elsif line=~/^pin\s*\((.*)\)/
		puts "Found pin: #{$section_name}" 
		$pin_id = insert_db("pins","name", $section_name)
	elsif line=~/^internal_power\s*\(\)/
		$lut_type = :internal_power
		$power_timing_id = insert_db("internal_power","pin_id",$pin_id)
	elsif line=~/^timing\s*\(\)/
		$lut_type = :timing
		$power_timing_id = insert_db("timing","pin_id",$pin_id)
	elsif line=~/^leakage_power\s*\(\)/
		section = :leakage_power
		$leakage_id = insert_db("leakage_power","cell_id", $cell_id)
	elsif line=~/index_1\((.*)/m
		$data_type = section.to_s
		section = :index_1
	elsif line=~/index_2\(/m
		section = :index_2
	elsif line=~/values\(/m
		section = :values
	end
	
	if section == :pin
		update_db("pins","cell_id",$cell_id,"id",$pin_id)
		store_pairs("pins",line,"id",$pin_id )
	elsif section == :cell 	
		store_pairs("cells",line,"name",$section_name)
	elsif section == :internal_power
		store_pairs("internal_power",line,"id",$power_timing_id)
	elsif section == :leakage_power
		store_pairs("leakage_power",line, "id", $leakage_id)
	elsif section == :timing
		store_pairs("timing", line, "id",$power_timing_id)
	elsif section == :index_1
		#puts "BEFORE " + line
		index_1_val = line.gsub("index_1(","")
		until line=~/\)\;/ #deal with multiple lines
			line = f.gets
			#puts "GOING " + line
			index_1_val += line
		end
		section=:nothing
		#puts "INDEX 1: " + index_1_val
		#$index_1_array = index_1_val.split(',').collect{|a| a.gsub("\"","").gsub("\\","").gsub(/\r\n?/,"")}
		#$index_1_array = index_1_val.split(',').collect{|a| a.gsub(/^([0-9]*\.?[0-9]+)/,"")}
		$index_1_array = index_1_val.split(',').collect{|a| a.gsub("index_1(","").gsub(/[^0-9\.]/,"")}
		$index_2_array = Array["NULL"]
		#puts "CHECK ME OUT1 " + $index_1_array[0]
	elsif section == :index_2
		index_2_val = line
		#puts "BEFORE: " + line
		until line=~/\)\;/ #deal with multiple lines
			line = f.gets
			#puts "GOING: " + line
			index_2_val += line
		end
		section=:nothing
		#puts "INDEX 2: " + index_2_val
		$index_2_array = index_2_val.split(',').collect{|a| a.gsub("index_2(","").gsub(/[^0-9\.]/,"")}
	elsif section == :values
		values = line
		until line=~/\)/ #deal with multiple lines
			line = f.gets
			values += line
		end
		section=:nothing
		#puts "VALUES: " + values
		values_array = values.split(',').collect{|a| a.gsub(/[^0-9\.]/,"")}
		store_values_db($pin_id,$data_type,$section_name,$index_1_array,$index_2_array,values_array)
		
		$index_1_array = Array["NULL"]
		$index_2_array = Array["NULL"]
	else
		#not in any section	
	end
end

rescue Mysql::Error => e
  puts "An error occurred"
  puts "Error code: #{e.errno}"
  puts "Error message: #{e.error}"
  puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
ensure
  $dbh.close if $dbh
end
