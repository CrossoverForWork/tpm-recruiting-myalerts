module Service
  class TrackerDeleter
    QUEUE  = ::QUEUE_TRACKERS

    # Use this to be able to send direct requests on dev
    URL    = ::TRACKERS_WORKER_URL
    PATH   = '/'.freeze
    METHOD = 'post'.freeze

    def initialize(options)
      @options                      = options
      @failure_messages_to_abort_on = options['failure_messages_to_abort_on'] || []

      @success_codes = [200, 204]
      @response      = { 'status'  => 'failure',
                         'message' => nil,
                         'code'    => 400,
                         'item'    => nil }
    end

    def call
      send_sqs_message
      @response['status'] = 'success'
      @response
    end

    protected

    def sqs_options
      { 'queue'        => QUEUE,
        'message_body' => sqs_message_body }
    end

    def sqs_message_body
      { 'klass'             => 'TrackerDeleter',
        'user_identifier'   => @options['user_identifier'],
        'client_identifier' => @options['client_identifier'],
        'client_data'       => @options['client_data'],
        'url'               => @options['url'],
        'list_slug'         => @options['list_slug'],
        'requested_at'      => Time.now.utc,
        'uuid'              => @options['uuid'],

        # Added to be able to send direct requests on dev
        'service_url'                  => URL,
        'path'                         => PATH,
        'method'                       => METHOD }
    end

    def send_sqs_message
      options = sqs_options
      ::Service::SQS::MessageSender.new(options).call
    end
  end
end
