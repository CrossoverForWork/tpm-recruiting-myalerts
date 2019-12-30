require_relative './base.rb'
module Service
  module Normalizer
    class PriceChange < Base
      def initialize(data)
        @limit = 3
        @data  = data
      end

      private

      def sort_data(data)
        # calculate savings of each price change
        savings_col = []
        data.each do |key, item|
          if data[key].is_a?(Hash)
            savings = (item['previous']['price'].to_f - item['current']['price'].to_f)
            savings_col << { key => savings }
          end
        end

        # order savings in desc order
        sorted = savings_col.sort_by { |key| key.values[0] }.reverse

        # rebuild the data ordered by savings
        ordered_data = {}
        sorted.each do |item|
          ordered_data[item.keys.first] = data[item.keys.first]
        end
        ordered_data
      end
    end
  end
end
