require 'phony'
require_relative './alert_sender'
module Service
  # Send alert to SMS pipeline (via SNS)
  class SmsSender < ::Service::AlertSender
    TOPIC = ::TOPIC_ALERTS_SMS

    def call
      raise StandardError, 'Missing expected SNS topic (TOPIC_ALERTS_SMS)' if TOPIC.nil?

      # TODO: error if client not configured for SMS
      fetch_external_data
      send_sns_message(sns_message_body)

      ::Service::FluentLogger.stream_logs(
        event:         'request',
        event_message: 'sms_alert_created',
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

    def sns_message_body
      contact_method = @user.contact_methods
                            .select { |p| p.label == 'phone' }
                            .select(&:enabled)
                            .select { |p| p.status == 'entered' }
                            .first

      contact_method = normalize_phone(contact_method.entry) if contact_method

      unless contact_method
        # NOTE FIXME why does it log and continue without phone number?
        ::Service::FluentLogger.stream_logs(
          event:         'request',
          event_message: 'sms_missing_phone',
          event_status:   'failure',
          uuid:           @uuid,
          alert_id:       @alert_id,
          client:         @client_data['whitelabel_url'],
          user_id:        @user.id,
          match_id:       @match_id,
          tracker_id:     @tracker_id
        )
      end

      # This is an array so we can support batches in the future
      # TODO: need better message versioning
      # TODO: verify outgoing JSON schema
      [
        {
          'notification' => @notification,
          'uuid'         => @uuid,

          'alert_id'          => @alert_id.to_s,
          'alert_type'        => @alert.type,
          'client_identifier' => @user.client_identifier,
          'client_uuid'       => @client_data['uuid'],
          'item_type'         => @alert_item['item_current_record']['data']['type'],
          'items'             => @alert_items.map { |item| map_item(item) },
          'matches'           => map_matches(@matches),
          'match_id'          => @match_id.to_s,
          'match_types'       => @alert.match_types,
          'tracker_id'        => @tracker_id.to_s,
          'user_id'           => @alert.user_id.to_s,
          'user_identifier'   => @user.user_identifier,
          'user_phone'        => contact_method ? contact_method : nil
        }.compact
      ]
    end

    # Format should be +12345678901
    def normalize_phone(phone)
      return unless phone

      normalized = Phony.normalize(phone)

      # check for (555) 321-4567 style numbers if no explicit country code on original
      if normalized.length == 10 && phone[0] != '+'
        normalized = '1' + normalized
      end

      # phony strips out + but twilio wants it
      return '+' + normalized if Phony.plausible?(normalized)

      # if we can't do anything smart, do nothing at all
      phone
    end

    def map_item(item)
      return unless item

      {
        'item_id'           => item['item_id'].to_s,
        'item_uuid'         => item['item_uuid'],
        'item_url'          => item['item_url'],
        'item_title'        => item['item_current_record']['data']['title'],
        'item_location'     => item['item_current_record']['data']['location']
      }.compact
    end

    def map_matches(matches)
      return unless matches

      all = matches.map do |match|
        # List style matches have multiple entires in the data block
        # but "singles" do not. make them look the same.
        list = {}
        if match.data['current'].nil?
          list = match.data
        else
          list[match.data['url']] = match.data
        end

        items = list.map do |item_url, item|
          {
            'match_name' => match.name,
            'match_id' => match.id.to_s,

            # TODO: figure out what this actually is 'item_id' => item['current']['id'] && item['current']['id'].to_s,
            'item_uuid' => item['item_uuid'],
            'item_url' => item_url,
            'item_title' => item['current']['title'],
            'item_location' => item['current']['location']
          }.compact
        end

        items
      end

      all.flatten!

      return if all.empty?

      all
    end

    def send_sns_message(body)
      TrackifMicroservices::MessageQueue.send_message_event(TOPIC, body.to_json, @uuid)
    end

    def fetch_external_data
      @alert = ::Service::Alert.where({ id: @alert_id }).first
      @user  = ::Service::User.where({ id: @alert.user_id }).first

      @alert_items = (@alert.data['items'] || {}).values
      @alert_item = @alert_items.first

      # TODO: warn if we see more than one match
      @match_id = @alert.data['matches_ids'].first
      @matches = ::Service::Match.where({ id: @alert.data['matches_ids'] })

      # TODO: warn if we see more than one tracker
      @tracker_id = @alert.data['trackers_ids'].first
      @tracker = ::Service::Tracker.where({ id: @tracker_id }).first
    end
  end
end
