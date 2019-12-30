#
# Class to send messages to SQS queue.
#
module Service
  module SQS
    class MessageSender
      def initialize(options)
        @queue = options['queue']
        @body  = options['message_body']
        @uuid = @body['uuid']
      end

      def call
        if ['production', 'staging'].include? ENV['RACK_ENV']
          TrackifMicroservices::MessageQueue.send_message(@queue, @body.to_json, @uuid)

        elsif ENV['RACK_ENV'] == 'development'
          conn = http_client(@body['service_url'])

          conn.post do |req|
            req.url @body['path']
            req.headers['Content-Type'] = 'application/json'
            req.body = @body['body'] ? @body['body'].to_json : @body.to_json
          end
        end
      end

      private

      def http_client(url)
        Faraday.new({ url: url }) do |faraday|
          faraday.request  :url_encoded
          faraday.response :json
          faraday.adapter  Faraday.default_adapter
        end
      end
    end
  end
end
