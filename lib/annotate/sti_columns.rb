require 'set'

module Annotate
  module StiColumns
    class << self
      def subclass?(klass)
        klass.superclass < ActiveRecord::Base &&
          klass.table_name == klass.superclass.table_name
      end

      def base_class?(klass)
        klass.column_names.include?(klass.inheritance_column) &&
          sti_descendants(klass).any?
      end

      def columns_referenced_in(klass)
        cols = Set.new
        cols.merge(klass.validators.flat_map { |v| v.attributes.map(&:to_s) })
        if klass.respond_to?(:reflect_on_all_associations)
          cols.merge(
            klass.reflect_on_all_associations(:belongs_to).flat_map { |a|
              fk = [a.foreign_key.to_s]
              fk << "#{a.name}_type" if a.respond_to?(:polymorphic?) && a.polymorphic?
              fk
            }
          )
        end
        cols.merge(klass.defined_enums.keys) if klass.respond_to?(:defined_enums)
        if klass.respond_to?(:stored_attributes) && klass.stored_attributes.any?
          cols.merge(klass.stored_attributes.keys.map(&:to_s))
        end
        cols
      end

      def columns_owned_by(klass)
        return Set.new unless subclass?(klass)

        columns_referenced_in(klass) - columns_referenced_in(klass.superclass)
      end

      def partition(klass, cols)
        if subclass?(klass)
          partition_for_subclass(klass, cols)
        elsif base_class?(klass)
          partition_for_base_class(klass, cols)
        else
          [[nil, cols]]
        end
      end

      private

      # Returns all descendants of klass that share the same table (STI).
      # Uses descendants (all levels) rather than subclasses (direct only)
      # to support multi-level STI hierarchies.
      #
      # Attempts eager loading first to ensure all subclasses are visible.
      def sti_descendants(klass)
        ensure_models_loaded
        if klass.respond_to?(:descendants)
          klass.descendants.select { |d| d.table_name == klass.table_name }
        else
          klass.subclasses.select { |d| d.table_name == klass.table_name }
        end
      end

      def ensure_models_loaded
        return if @models_loaded

        if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
          Rails.application.eager_load! unless Rails.application.config.eager_load
        end
        @models_loaded = true
      end

      def partition_for_subclass(klass, cols)
        owned = columns_owned_by(klass)
        base_name = klass.superclass.name.demodulize
        shared = cols.reject { |c| owned.include?(c.name.to_s) }
        specific = cols.select { |c| owned.include?(c.name.to_s) }

        if specific.empty?
          $stderr.puts "Warning: --group-sti-columns could not determine which columns belong to #{klass.name}."
          $stderr.puts "  Add validations, associations, or enums to #{klass.name} to improve grouping."
        end

        groups = []
        groups << ["#{base_name} columns", shared] if shared.any?
        groups << ["#{klass.name.demodulize} columns", specific] if specific.any?
        groups
      end

      def partition_for_base_class(klass, cols)
        all_descendants = sti_descendants(klass).sort_by(&:name)
        ownership = {}

        all_descendants.each do |sub|
          columns_owned_by(sub).each do |col_name|
            ownership[col_name] ||= sub.name.demodulize
          end
        end

        base_cols = cols.reject { |c| ownership.key?(c.name.to_s) }
        groups = [["#{klass.name.demodulize} columns", base_cols]]

        all_descendants.each do |sub|
          sub_name = sub.name.demodulize
          sub_cols = cols.select { |c| ownership[c.name.to_s] == sub_name }
          groups << ["#{sub_name} columns", sub_cols] if sub_cols.any?
        end

        if ownership.empty?
          $stderr.puts "Warning: --group-sti-columns found STI subclasses for #{klass.name} but no columns could be assigned."
          $stderr.puts "  Add validations, associations, or enums to subclasses to improve grouping."
        end

        groups
      end
    end
  end
end
