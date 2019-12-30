require_relative './alert_sender'
require_relative '../alerts_builder'

module Service
  # Send alert to SendGrid pipeline (via SQS)
  class EmailAlertSender < ::Service::AlertSender
    QUEUE = ::QUEUE_EMAIL_ALERTS_URL

    # Use this to be able to send direct requests on dev
    URL   = ::ALERTS_BUILDER_URL
    PATH   = '/'.freeze
    METHOD = 'post'.freeze

    def call
      if ALERTS_BUILDER_ENABLED
        service = ::Service::AlertsBuilder.new(sqs_message_body)
        @response = service.call
      else
        send_sqs_message
      end

      @response['status'] = 'success'
      @response
    end

    protected

    def sqs_options
      { 'queue'        => QUEUE,
        'message_body' => sqs_message_body }
    end

    def sqs_message_body
      { 'alert_id'     => @alert_id,
        'notification' => @notification,
        'uuid'         => @options['uuid'],
        'client_data'  => @client_data,
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
