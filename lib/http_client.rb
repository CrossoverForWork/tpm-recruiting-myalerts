#
# HTTP Client.
#
module Service
  class HTTPClient
    DEFAULT_CACHE_EXPIRATION = 3600

    def initialize(options)
      @url              = options['url']
      @cache            = options['cache']
      @cache_expiration = options['cache_expiration'] || DEFAULT_CACHE_EXPIRATION
    end

    def call
      Faraday.new({ url: @url }) do |faraday|
        if @cache
          faraday.use :http_cache, { store: ::Service::CACHE_STORE, shared_cache: false }
        end
        faraday.request  :url_encoded
        faraday.response :json
        faraday.adapter  Faraday.default_adapter
      end
    end
  end
end
