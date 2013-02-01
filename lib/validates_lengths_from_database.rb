require "rubygems"
require "active_record"

module ValidatesLengthsFromDatabase
  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    def validates_lengths_from_database(options = {})
      options.symbolize_keys!

      return false unless self.table_exists?
      options[:only]    = Array[options[:only]]   if options[:only] && !options[:only].is_a?(Array)
      options[:except]  = Array[options[:except]] if options[:except] && !options[:except].is_a?(Array)
      options[:limit] ||= {}

      if options[:limit] and !options[:limit].is_a?(Hash)
        options[:limit] = {:string => options[:limit], :text => options[:limit]}
      end

      if options[:only]
        columns_to_validate = options[:only].map(&:to_s)
      else
        columns_to_validate = column_names.map(&:to_s) + alias_attribute_method_map.keys.map(&:to_s)
        columns_to_validate -= options[:except].map(&:to_s) if options[:except]
      end

      columns_to_validate.each do |column|
        attribute_name = column
        column = alias_attribute_method_map[column] if alias_attribute_method_map.has_key?(column)
        column_schema = columns.find {|c| c.name == column }
        next if column_schema.nil?
        next if ![:string, :text].include?(column_schema.type)

        column_limit = options[:limit][column_schema.type] || column_schema.limit
        next unless column_limit

        class_eval do
          validates_length_of attribute_name, :maximum => column_limit, :allow_blank => true
        end
      end

      nil
    end

    def alias_attribute(new_name, old_name)
      super
      alias_attribute_method_map[new_name.to_s] = old_name.to_s
    end

    def alias_attribute_method_map
      @alias_attribute_method_map ||= HashWithIndifferentAccess.new
    end

  end

  module InstanceMethods
  end
end

require "validates_lengths_from_database/railtie"
