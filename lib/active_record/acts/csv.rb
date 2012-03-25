require 'csv'
module ActiveRecord
  module Acts
    module Csv
      def self.included(base)
        base.extend ClassMethods
        ::ActiveRecord::Relation.send(:include, ClassMethods)
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def to_csv(opts={})
          fields = if opts[:fields]
                     opts.delete(:fields)
                   elsif respond_to?(:attribute_names)
                     attribute_names
                   elsif self.is_a?(ActiveRecord::Relation)
                     @klass.new.attribute_names
                   else
                     new.attribute_names
                   end
          CSV.generate do |csv|
            csv << fields.map{|f|
              name = human_attribute_name(f)
              opts[:encoding] ? name.encode(opts[:encoding]) : name
            } unless opts[:without_header]
            all.each{|row| csv << row.to_csv_ary(fields) }
          end
        end
      end

      module InstanceMethods
        def to_csv_ary(fields=nil, opts={})
          fields = attribute_names unless fields
          fields.map{|field|
            convert_method = "#{field}_as_csv"
            method = respond_to?(convert_method) ? convert_method : field
            value = send(method)
            opts[:encoding] ? value.to_s.encode(opts[:encoding]) : value
          }
        end
      end
    end
  end
end
