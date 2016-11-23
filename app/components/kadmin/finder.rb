# frozen_string_literal: true
module Kadmin
  class Finder
    include Kadmin::Presentable

    # @return [Kadmin::Pager] the pager to use (if any)
    attr_reader :pager

    # @return [Array<Kadmin::Finder::Filter>] array of filters applied to the finder
    attr_reader :filters

    # @return [ActiveRecord::Relation] the base relation to find items from
    attr_reader :scope

    # Simple filter structure
    Filter = Struct.new(:column, :value)

    # @param [ActiveRecord::Relation] scope base relation to page/filter on
    def initialize(scope)
      @scope = scope
      @pager = nil
      @filters = {}
      @results = nil
      @filtering = false
    end

    # @param [String] name the filter name (should be unique)
    # @param [String, Array<String>] column the column(s) name to filter on
    # @param [String, Array<String>] value the value or values to look for (OR'd)
    def filter(name:, column:, value:)
      if column.present? && !@filters.key?(name)
        @filters[name] = Kadmin::Finder::Filter.new(column, value)
        if value.present?
          @scope = @scope.where("#{@scope.table_name}.`#{column}` LIKE ?", "%#{value}%".squeeze('%'))
          @filtering = true
        end
      end

      return self
    end

    def filtering?
      return @filtering
    end

    # @param [Integer] offset optional; offset/index for the current page
    # @param [Integer] size optional; size of a page
    # @return [Kadmin::Finder] itself
    def paginate(offset: nil, size: nil)
      offset = offset.to_i
      size = size.to_i

      if size.positive? && offset >= 0
        @pager = Kadmin::Pager.new(size: size, offset: offset)
      end

      return self
    end

    # @return [ActiveRecord::Relation] the filtered (and optionally paginated) results
    def results
      return @results ||= begin
        results = @scope
        results = @pager.paginate(results) unless @pager.nil?
        Rails.logger.info('Right before loading')
        results.load
        Rails.logger.info('Right after loading')
        results
      end
    end

    def find!
      @total_found = 0
      @results = nil
      return results
    end
  end
end