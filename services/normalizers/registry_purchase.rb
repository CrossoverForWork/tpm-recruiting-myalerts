require_relative './base.rb'
module Service
  module Normalizer
    class RegistryPurchase < Base
      def initialize(data)
        @limit = 10
        @data  = data
      end
    end
  end
end
