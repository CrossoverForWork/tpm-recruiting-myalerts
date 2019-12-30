require_relative './alert_sender'
module Service
  # Send alert to external hook pipeline (via SQS)
  class ExternalAlertSender < ::Service::AlertSender
    QUEUE = ::QUEUE_EXTERNAL_ALERTS_URL

    # Use this to be able to send direct requests on dev
    URL   = ::ALERTS_BUILDER_URL
    PATH   = '/'.freeze
    METHOD = 'post'.freeze

    def call
      fetch_external_data
      send_sqs_message

      ::Service::FluentLogger.stream_logs(
        event:         'request',
        event_message: 'external_alert_created',
        event_status:  'success',
        uuid:          @uuid,
        alert_id:      @alert_id,
        user_id:       @user.id,
        client:        @client_data['whitelabel_url']
      )

      @response['status'] = 'success'
      @response
    end

    protected

    def sqs_options
      { 'queue'        => QUEUE,
        'message_body' => sqs_message_body }
    end

    def sqs_message_body
      {
        'notification' => @notification,
        'alert_data'   => {
          'alert_id'   => @alert_id,
          'triggers'   => @tracker.triggers
        },
        'item_data' => {
          'item_url'  => @alert.data['items'].first[1]['item_url'],
          'sku'       => @tracker.meta['origin']['tracker']['matching']['sku'],
          'title'     => @alert.data['items'].first[1]['item_current_record']['data']['title']
        },
        'user_data' => {
          'email' => @user.user_identifier,
          'client_identifier' => @user.client_identifier
        },
        'uuid' => @options['uuid'],

        # Added to be able to send direct requests on dev
        'service_url'                  => URL,
        'path'                         => PATH,
        'method'                       => METHOD
      }
    end

    def send_sqs_message
      options = sqs_options
      ::Service::SQS::MessageSender.new(options).call
    end

    def fetch_external_data
      @alert = ::Service::Alert.where({ id: @alert_id }).first
      @user  = ::Service::User.where({ id: @alert.user_id }).first

      tracker_id = @alert.data['items'].first[1]['tracker_id']
      # This will not work for digest type alerts that can
      # have multiple trackers
      @tracker = ::Service::Tracker.where({ id: tracker_id }).first
    end
  end
end
