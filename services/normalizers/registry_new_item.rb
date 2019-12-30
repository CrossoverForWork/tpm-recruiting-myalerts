require_relative './base.rb'
module Service
  module Normalizer
    class RegistryNewItem < Base
      def initialize(data)
        @limit = 3
        @data  = data
      end
    end
  end
end
