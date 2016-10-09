require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
	#getting the table name from the class name
	def self.table_name
		self.to_s.downcase.pluralize
	end

	#getting the column names into an array from a hash
	def self.column_names
		DB[:conn].results_as_hash = true

		sql = "PRAGMA table_info('#{table_name}')"
		table_info = DB[:conn].execute(sql)
		column_names = []

		table_info.each do |column|
			column_names << column["name"]
		end

		column_names.compact
	end

	#getting the argument into a hash of values to initialize with
	def initialize(options = {})
		options.each do |property, value|
			self.send("#{property}=", value)
		end
	end

	#using the table name for an instance variable
	def table_name_for_insert
		self.class.table_name
	end

	#removing the id column, since that is automatically set, and converting the column names to a string from an array
	def col_names_for_insert
		self.class.column_names.delete_if {|col| col == "id"}.join(', ')
	end

	#getting the values to make the objects
	def values_for_insert
		values = []

		self.class.column_names.each do |col_name|
			values << "'#{send(col_name)}'" unless send(col_name).nil?
		end
		values.join(', ')
	end

	def save
		sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
		DB[:conn].execute(sql)
		@id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
	end

	def self.find_by_name(name)
		sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
		DB[:conn].execute(sql)
	end

	def self.find_by(attributes_hash)
		# check_key = attribute_hash.values.first
		# check_value = attribute_hash.keys.first
		sql = "SELECT * FROM #{self.table_name} WHERE #{attributes_hash.keys[0]} = '#{attributes_hash.values[0]}'"
		DB[:conn].execute(sql)
	end
end