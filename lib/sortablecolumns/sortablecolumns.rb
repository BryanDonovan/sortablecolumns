# Sortablecolumns Rails Plugin
# Lets you define column definitions for a sortable HTML table.
# Author: Bryan Donovan 
# March 2008

require 'active_record'
require 'active_support'
require 'active_support/core_ext/hash/keys'
require 'action_controller'

module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Sortablecolumns
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
      end

      module ClassMethods
        #include ActiveSupport::CoreExtensions::Hash::Keys

        # == Configuration options
        #
        # * <tt>sorter_name</tt> (required) - specify the name of the sorter, same name used for YAML file, method prefixes
        # * <tt>subclass_name</tt> (optional) - specify the subclass name if your model inherits from another model.  You must create your YAML file in a subdirectory of the same name (lowercase).  E.g., app/models/person/manager_sorter.yml for a Manager model that inherits from the Person model.
        # * <tt>path_prefix</tt> (optional) - path to your column definitions directory where your YAML files are stored (relative to RAILS_ROOT). If this isn't specified, Sortablecolumns looks for column definitions in /app/models/col_defs, but you must create that directory manually.  
        # == Examples
        # class Person < ActiveRecord::Base
        #   sortable_columns :mysorter
        #   sortable_columns :othersorter, :path_prefix => '/my_column_defs'
        # end

        # class Manager < Person
        #   sortable_columns :manager_sorter, :subclass_name => 'Manager' 
        # end
        def sortable_columns(sorter_name, options = {})
          options = {:subclass_name => nil, :path_prefix => nil}.merge(options)
          write_inheritable_attribute(:sorter_options, options)
          class_inheritable_reader :sorter_options

          self.class_eval <<-END
          def self.#{sorter_name}_cols=(val)
            @@#{sorter_name}_cols = val
          end

          def self.#{sorter_name}_cols
            @@#{sorter_name}_cols
          end
          cattr_accessor :#{sorter_name}_cols

          def self.#{sorter_name}_col_defs
            @@#{sorter_name}_cols ||= #{sorter_name}_initialize_col_defs
          end

          def self.#{sorter_name}_col_text(obj, col)
            if self.#{sorter_name}_in_resultset?(col)
              ret = obj.send(col)
              if ret == '' or ret.nil?
                ret = "&nbsp;".html_safe #so empty TD cells still get displayed
              end
              return ret
            end
            return self.#{sorter_name}_print_text(col)
          end

          def self.#{sorter_name}_yaml_path
            raise "RAILS_ROOT is not defined" unless defined?(RAILS_ROOT)
            klass_name = ActiveSupport::Inflector.underscore(self.table_name.classify)
            file_name = "#{sorter_name}.yml"
            if sorter_options[:subclass_name]
              sub_path = File.join(klass_name, ActiveSupport::Inflector.underscore(sorter_options[:subclass_name]), file_name)
            else
              sub_path = File.join(klass_name, file_name)
            end
            if sorter_options[:path_prefix]
              return File.join(RAILS_ROOT, sorter_options[:path_prefix], sub_path)
            else
              #defaults to col_defs subdirectory in app/models
              return File.join(RAILS_ROOT, "app/models/col_defs", sub_path)
            end
          end

          def self.#{sorter_name}_initialize_col_defs
            if "#{sorter_name}" == 'default_sorter'
              self.default_col_defs
            else
              YAML.load_file(#{sorter_name}_yaml_path)
            end
          end

          def self.#{sorter_name}_col_def_hash
            @@#{sorter_name}_col_def_hash ||= #{sorter_name}_initialize_col_def_hash
          end

          def self.#{sorter_name}_initialize_col_def_hash
            col_def_hash = {}
            #{sorter_name}_col_defs.each do |c|
              c.keys.each do |key|
                col_def_hash[key] = c[key]
              end
            end
            col_def_hash
          end

          def self.#{sorter_name}_col_keys_in_order
            @@#{sorter_name}_col_keys_in_order ||= #{sorter_name}_initialize_col_keys_in_order
          end

          def self.#{sorter_name}_initialize_col_keys_in_order
            cols = []
            #{sorter_name}_col_defs.each do |hsh|
              hsh.each do |key, sub_hash|
                cols << key
              end
            end
            cols
          end

          def self.#{sorter_name}_heading(col)
            return false if #{sorter_name}_col_def_hash[col]['heading'] == false
            #{sorter_name}_col_def_hash[col]['heading'] || col.humanize
          end

          def self.#{sorter_name}_headings_in_order
            @@#{sorter_name}_headings_in_order ||= #{sorter_name}_initialize_headings_in_order
          end

          def self.#{sorter_name}_initialize_headings_in_order
            headings = []
            #{sorter_name}_col_keys_in_order.each do |key|
              headings << #{sorter_name}_heading(key) if #{sorter_name}_heading(key)
            end
            headings
          end

          def self.#{sorter_name}_col_def(col)
            #{sorter_name}_col_def_hash[col]
          end

          def self.#{sorter_name}_datatype(col)
            #{sorter_name}_col_def_hash[col]['datatype']
          end

          def self.#{sorter_name}_sort_options(col)
            #{sorter_name}_col_def_hash[col]['sort_options']
          end

          def self.#{sorter_name}_default_sort_dir(col)
            if sort_ops = #{sorter_name}_col_def_hash[col]['sort_options']
              sort_ops['default_dir'] ? sort_ops['default_dir'] : 'asc'
            else 
              'asc'
            end
          end

          def self.#{sorter_name}_print_options(col)
            if #{sorter_name}_col_def_hash[col]
              #{sorter_name}_col_def_hash[col]['print_options']
            end
          end

          def self.#{sorter_name}_td_class(col)
            #{sorter_name}_col_def_hash[col]['td_class']
          end

          def self.#{sorter_name}_th_class(col)
            #{sorter_name}_col_def_hash[col]['th_class']
          end

          def self.#{sorter_name}_precision(col)
            #{sorter_name}_col_def_hash[col]['precision']
          end

          def self.#{sorter_name}_delimiter(col)
            #{sorter_name}_col_def_hash[col]['delimiter'] || ","
          end

          def self.#{sorter_name}_separator(col)
            #{sorter_name}_col_def_hash[col]['separator'] || "."
          end

          def self.#{sorter_name}_unit(col)
            #{sorter_name}_col_def_hash[col]['unit'] || "$"
          end

          def self.#{sorter_name}_date_format(col)
            format = #{sorter_name}_col_def_hash[col]['date_format']
            unless format
              datatype = #{sorter_name}_datatype(col)
              if datatype.downcase == 'datetime'
                format = "%Y-%m-%d %I:%M:%S"
              else
                format = "%Y-%m-%d"
              end
            end
            format
          end

          def self.#{sorter_name}_print_text(col)
            #{sorter_name}_col_def_hash[col]['print_text'] || '' 
          end

          def self.#{sorter_name}_sortable?(col)
            hsh = #{sorter_name}_col_def_hash[col]
            return false if hsh.has_key?('sortable') && hsh['sortable'] == false
            return false if hsh.has_key?('heading') && hsh['heading'] == false
            return true
          end

          def self.#{sorter_name}_link_options(col)
            link_ops = #{sorter_name}_col_def_hash[col]['link_options']
            return link_ops.symbolize_keys! if link_ops 
          end

          def self.#{sorter_name}_link?(col)
            return true if #{sorter_name}_link_options(col)
            return false
          end

          def self.#{sorter_name}_in_resultset?(col)
            hsh = #{sorter_name}_col_def_hash[col]
            return false if hsh.has_key?('in_resultset') && hsh['in_resultset'] == false
            return true
          end

          def self.#{sorter_name}_col_def_for_yui(col)
            label = #{sorter_name}_heading(col) ? #{sorter_name}_heading(col) : ''
            sortable = #{sorter_name}_sortable?(col)
            datatype = #{sorter_name}_datatype(col)
            if datatype == 'number' or datatype == 'currency'
              formatter = datatype
            end
            sort_dir = #{sorter_name}_default_sort_dir(col)
            if sort_dir == 'desc'
              sort_ops =  {:defaultDir => "YAHOO.widget.DataTable.CLASS_DESC"}
            end
            yui = {:key => col, :label => label, :sortable => sortable}
            yui[:sortOptions] = sort_ops  if sort_ops
            yui[:formatter]   = formatter if formatter
            yui
          end

          def self.#{sorter_name}_col_defs_for_yui
            yui_col_defs = [] 
            #{sorter_name}_col_keys_in_order.each do |col|
              yui_col_defs << #{sorter_name}_col_def_for_yui(col)
            end
            yui_col_defs
          end

          def self.#{sorter_name}_field_def_for_yui(col)
            datatype = #{sorter_name}_datatype(col)
            yui_field_def = {:key => col}
            if datatype == 'number'
              yui_field_def[:parser] = "YAHOO.util.DataSource.parseNumber"
            end
            if  datatype == 'currency'
              yui_field_def[:parser] = "this.parseNumberFromCurrency"
            end
            yui_field_def
          end

          def self.#{sorter_name}_fields_for_yui
            yui_fields = []
            #{sorter_name}_col_keys_in_order.each do |col|
              yui_fields << #{sorter_name}_field_def_for_yui(col)
            end
            yui_fields
          end


          def self.default_col_defs(output=:hsh)
            col_arr = []
            col_hsh = self.columns_hash
            self.column_names.each do |col_name|
              hsh = {}
              col = col_hsh[col_name]
              hsh[col.name] = {}
              h = hsh[col.name]
              h['heading'] = col.name.titleize
              if col.limit && col.limit > 50
                h['sortable'] = 'false'
              end
              if col.type == :date
                h['datatype'] = 'date'
              end
              if col.type == :datetime
                h['datatype'] = 'datetime'
              end
              if col.type == :integer
                h['datatype'] = 'number'
                h['sort_options'] = {'default_dir' => 'asc'}
              end
              if col.name.match(/amt|cost|price|balance/)
                h['datatype'] = 'currency'
                h['sort_options'] = {'default_dir' => 'desc'}
              elsif col.type == :decimal
                h['datatype'] = 'number'
                h['precision'] = 2
                h['sort_options'] = {'default_dir' => 'asc'}
              end
              col_arr << hsh
            end
            return col_arr if output == :hsh
            return col_arr.to_yaml
          end

          END

        end #sortable_columns
      end #ClassMethods
    end #Sortablecolumns
  end #Acts
end #ActiveRecord
