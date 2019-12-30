module Service
  class AlertsGenerator
    def initialize(options)
      @options = options
      @client_identifier = options['client_identifier']
      @user_id           = options['user_id']
      @user              = ::Service::User.where({ id: @user_id }).first
      @user_identifier   = @user.try(:user_identifier)
      @uuid              = options['uuid']
      @matches           = nil
      @trackers          = nil
      @requested_type    = options['requested_type']
      @requested_data    = options['requested_data'] || []
      @client_data       = client_config
      @client_config     = @client_data['alerts']
      @response          = { 'status'  => 'failure',
                             'data'    => {},
                             'message' => nil }
    end

    def call
      @response = {
        'status' => 'success',
        'data' => {
          'sent' => 0
        },
        'message' => 'received'
      }

      unless generate_alerts?
        @response['message'] = 'disabled'
        return @response
      end

      # The code does not properly reflect the different scenarios for building
      # alerts.
      # Alerts of type 'now_tracking' and 'new_account' do not have matches.
      if @requested_data.include?('now_tracking') || @requested_data.include?('new_account')
        # Fetch tracker records, and eager load associations.
        @trackers = get_trackers(@options['trackers_ids'])
        @matches  = [] # See build_alerts_data() .. I don't want to refactor the entire thing.
      else
        # Fetch matches records (with a limit) and eager load trackers and items.
        @matches = get_matches(@options['trackers_ids'], @options['qa_digest'])
      end

      alerts_data = build_alerts_data

      alerts = alerts_data
               .each_with_object({}) { |data, merged| merge_alerts!(data, merged) }
               .values

      created = alerts.map { |alert| create_alert_record(alert) }

      if dispatch_alerts?
        send_notifications({ 'alerts' => created, 'uuid' => @uuid, 'client_data' => @client_data })
      end

      @response['message'] = 'processed'
      @response['data']['sent'] = created.count
      @response
    end

    protected

    def generate_alerts?
      @client_data['switches']['alerts']['creation']
    end

    def dispatch_alerts?
      @client_data['switches']['alerts']['dispatch']
    end

    def alert_enabled?(alert_data)
      match_config = @client_config['matches'][alert_data['match_name']]
      return unless match_config['enabled']

      match_config['alertable'].nil? ? true : match_config['alertable']
    end

    def alert_requested?(alert_data)
      @requested_data.include?(alert_data['request_type'])
    end

    def alert_once?
      @client_config['single_alert']
    end

    def build_alerts_data
      alerts      = []
      alert_type  = @requested_type
      user_id     = @user_id
      @trackers ||= @matches.map(&:tracker)

      @trackers.each do |tracker|
        # This should not happen..
        # It checks to see if the item the tracker points to
        # has information, in order to avoid another query
        # to get the item_record it will simply check against
        # its status, where "created" means it is active
        # (yeah it is weird ..).
        if ! tracker.item.created?
          ::Service::FluentLogger.stream_logs(
            event:          'request',
            event_message:  'skip_invalid_item',
            event_status:   'failure',
            log_level:      'warning',
            uuid:            @uuid,
            client:          @client_identifier,
            user_id:         @user_id,
            item_url:        tracker.item.url,
            tracker_id:      tracker.id
          )
          next
        end

        tracker_matches = @matches.find_all { |m| m.tracker_id == tracker.id }
        notification_methods = tracker.notification_methods || []
        notification_methods << 'email' if notification_methods.empty?

        notification_methods.each do |notification_method|
          alerts << build_alert_data({
            'alert_type' => alert_type,
            'match_name' => 'now_tracking',
            'notification_method' => notification_method,
            'request_type' => 'now_tracking',
            'tracker' => tracker,
            'user_id' => user_id
          })
          alerts << build_alert_data({
            'alert_type' => alert_type,
            'match_name' => 'new_account',
            'notification_method' => notification_method,
            'request_type' => 'new_account',
            'tracker' => tracker,
            'user_id' => user_id
          })

          processed   = []
          matches_ids = tracker_matches.map(&:id).uniq
          tracker_matches.each do |match|
            next if processed.include?(match.name) # Ignore match duplicates.
            match.data['match_id'] = match.id
            opts = {
              'alert_type'          => alert_type,
              'match_data'          => match.data,
              'match_name'          => match.name,
              'matches_ids'         => matches_ids,
              'notification_method' => notification_method,
              'request_type'        => 'matches',
              'tracker'             => tracker,
              'user_id'             => user_id
            }
            alerts    << build_alert_data(opts)
            processed << match.name
          end
        end

        # TODO: should probably happen after alert is sent
        delete_tracker(tracker) if alert_once?
      end

      alerts
        .select { |data| alert_enabled?(data) }
        .select { |data| alert_requested?(data) }
    end

    def create_alert_record(alert_data)
      alert = ::Service::Alert.new do |a|
        a.template    = alert_data['template']
        a.data        = alert_data['data']
        a.user_id     = alert_data['user_id']
        a.type        = alert_data['alert_type']
        a.match_types = alert_data['match_types'].uniq
      end

      alert.save

      if alert_data['trackers_ids']
        alert_data['trackers_ids'].uniq.each { |tracker_id| alert.add_tracker(tracker_id) }
      end

      if alert_data['matches_ids']
        alert_data['matches_ids'].uniq.each { |match_id| alert.add_match(match_id) }
      end

      alert
    end

    def merge_alerts!(alert_data, alerts)
      # Only send one alert per notification_method and template pair
      merge_key = "#{alert_data['notification_method']}:#{alert_data['template']}"
      alerts[merge_key] ||= {
        'notification_method' => alert_data['notification_method'],
        'template' => alert_data['template'],
        'user_id' => alert_data['user_id'],

        'data' => {
          'match_types' => [],
          'matches_ids' => [],
          'items' => {}
        }
      }

      old = alerts[merge_key]
      merged = merge_alert_data!(old['data'], alert_data)

      # This copy step is odd because a lot of the contents in the .data block
      # are the same as what lives on the alert record itself.
      old['alert_type'] = merged['alert_type']
      old['match_types'] = merged['match_types']
      old['trackers_ids'] = merged['trackers_ids']
      old['matches_ids'] = merged['matches_ids']

      alerts
    end

    def merge_alert_data!(old, alert_data)
      old['match_types'] = (old['match_types'] + alert_data['match_types']).uniq
      old['matches_ids'] += alert_data['matches_ids']
      old['matches_ids'].uniq!

      if alert_data['trackers_ids']
        old['trackers_ids'] ||= []
        old['trackers_ids'] = (old['trackers_ids'] + alert_data['trackers_ids']).uniq
      end

      old['alert_type'] ||= alert_data['alert_type']

      item_id = alert_data['item_id']
      match_name = alert_data['match_name']

      old['items'][item_id] ||= alert_data['item_data']
      old['items'][item_id]['matches'][match_name] = alert_data['match_data']
      old['notification_method'] ||= alert_data['notification_method']

      old
    end

    def build_alert_data(data)
      alert_data = {
        'match_types' => [data['match_name']],
        'matches_ids' => data['matches_ids'] || [],
        'alert_type' => data['alert_type'],
        'items' => {},
        'notification_method' => data['notification_method'] || 'email'
      }
      alert_data['trackers_ids'] = [data['tracker'].id] if data['tracker']

      match_data = data['match_data'] || {}
      # HACK: avoid trying to get item_title consistent across the differing match.data shapes (OUTPUT 135)
      match_data.delete('item_title')

      item_data = build_item_data(data['tracker']) || { 'matches' => {} }
      item_data['matches'][data['match_name']] = match_data
      alert_data['items'][item_data['item_id']] = item_data

      {
        'template' => template_for_match_name(data['match_name']),
        'data' => alert_data,
        'alert_type' => data['alert_type'],
        'item_data' => item_data,
        'item_id' => item_data['item_id'],
        'match_data' => match_data,
        'match_name' => data['match_name'],
        'match_types' => alert_data['match_types'],
        'matches_ids' => alert_data['matches_ids'],
        'notification_method' => alert_data['notification_method'],
        'request_type' => data['request_type'],
        'tracker' => data['tracker'],
        'trackers_ids' => alert_data['trackers_ids'],
        'user_id' => data['user_id']
      }
    end

    def build_item_data(tracker)
      return unless tracker
      return unless tracker.item
      return unless tracker.item.current_record

      item         = tracker.item
      item_record  = tracker.item.current_record

      {
        'tracker_id' => tracker.id,
        'item_id' => item.id,
        'item_uuid' => item.uuid,
        'item_url' => item.url,
        'item_current_record' => {
          'data' => item_record.data,
          'digest' => item_record.digest,
          'id' => item_record.id
        },
        'matches' => {},
        'tracker' => {
          'meta' => tracker.meta,
          'created_at' => tracker.created_at
        }
      }
    end

    def client_config
      options = { 'whitelabel_url' => @client_identifier, 'uuid' => @options['uuid'] }
      ::Service::ClientReader.new(options).call['data']
    end

    def template_for_match_name(match_name)
      @client_config['matches'][match_name]['template']
    end

    def client_matches_limit
      @client_config['matches_limit'] || 10
    end

    # Return trackers and eager load associations.

    def get_trackers(trackers_ids)
      ::Service::Tracker.eager(:item)
                        .where(Sequel.lit('id IN ?', trackers_ids)).all
    end

    # Return matches and eager load tracker and item records for the set of tracker IDs.
    # This function executes three database queries to get all matches, trackers and items.

    def get_matches(trackers_ids, qa_digest = false)
      limit     = client_matches_limit
      sql_query = 'alert_id IS NULL AND created_at >= ? AND created_at <= ?'
      sql_args  = [Time.now.utc - 43200, Time.now.utc]
      if qa_digest
        sql_query += ' AND user_id = ?'
        sql_args  += [@user_id.to_i]
      else
        sql_query += ' AND tracker_id IN ?'
        sql_args  += [trackers_ids]
      end
      ::Service::Match.eager(:tracker => :item)
        .where(Sequel.lit(sql_query, *sql_args)).limit(limit).all
    end

    def send_notifications(options)
      options['alerts'].each do |alert|
        notification_method = alert.data['notification_method'] # TODO: make this a real column
        notification_method ||= 'email' if alert.trackers.empty?
        notification_method ||= alert.trackers.first.notification_methods.first

        data = { 'alert_id'     => alert.id,
                 'notification' => notification_method,
                 'client_data'  => options['client_data'],
                 'uuid'         => options['uuid'] }
        ::Service::AlertSender.build(data).call
      end
    end

    def delete_tracker(tracker)
      return if @requested_data.include?('now_tracking') || @requested_data.include?('new_account')

      options = {
        'user_identifier'   => tracker.user.user_identifier,
        'client_identifier' => @client_identifier,
        'client_data'       => @client_config,
        'url'               => tracker.item.url,
        'list_slug'         => tracker.list.slug,
        'uuid'              => @options['uuid']
      }
      ::Service::TrackerDeleter.new(options).call
    end
  end
end
