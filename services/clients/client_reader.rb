#
# Service for reading client information.
#
module Service
  class ClientReader
    def initialize(options)
      @options  = options
      @response = { 'status' => 'failure', 'data' => nil }
      @use_cache = true
    end

    # Returns client information.
    def call
      client   = ::Service::HTTPClient.new({ 'url' => CLIENTS_API_URL, 'cache' => @use_cache }).call
      response = client.get do |request|
        request.url "clients/#{@options['whitelabel_url']}"
      end
      @response['data']   = response.body['data']
      @response['status'] = response.status == 200 ? 'success' : 'failure'
      @response
    end
  end
end
