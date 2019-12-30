module Service
  module Normalizer
    class Base
      def initialize(data)
        @data = data
        @limit = 3
      end

      def call
        return unless @data

        sorted  = sort_data(@data)
        limited = limit_data(sorted)
        @data   = limited.merge(extra_data)
      end

      private

      def sort_data(data)
        # calculate savings of each price change
        savings_col = []
        data.each do |key, item|
          if data[key].is_a?(Hash)
            savings = item['current']['price'].to_f
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

      def limit_data(data)
        limited = {}
        i = 0
        while (i < @limit) && (i < data.length)
          url = data.keys[i]
          limited[url] = data[url]
          i += 1
        end
        limited
      end

      def extra_data
        {}
      end
    end
  end
end
