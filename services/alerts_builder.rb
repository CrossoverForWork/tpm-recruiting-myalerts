require 'erb'
require 'premailer'
require 'securerandom'

module Service
  class AlertsBuilder
    QUEUE = ::QUEUE_TEMPLATE_INTERPOLATION
    QUEUE_DIGEST = ::QUEUE_TEMPLATE_INTERPOLATION_DIGEST

    def initialize(options)
      @alert       = ::Service::Alert.where({ id: options['alert_id'] }).first
      @uuid        = options['uuid']
      @client_data = options['client_data']

      @response    = { 'status'  => 'failure',
                       'message' => '' }
    end

    def call
      @response['uuid'] = @uuid
      @response['email'] = @alert.user.user_identifier

      recipients = [@alert.user.user_identifier]

      if override_enabled?
        recipients = override_recipients
        @response['email'] = override_recipients
      end

      messages = []

      recipients.each do |recipient|
        if registry?
          @alert.data['items'].each do |item_id, item_data|
            messages << {
              alert: @alert,
              recipient: recipient,
              item_id: item_id,
              item_data: item_data,
              client_data: @client_data,
              uuid: @uuid
            }
          end
        else
          messages << {
            alert: @alert,
            recipient: recipient,
            client_data: @client_data,
            uuid: @uuid
          }
        end
      end

      messages.each do |message|
        send_sqs_message(message)
      end

      @response['status'] = 'success' # always success since it's sending to SQS queue
      @response
    end

    protected

    def registry?
      @alert.type == 'registry'
    end

    def override_enabled?
      @client_data['switches']['alerts']['recipient_override']['enabled']
    end

    def override_recipients
      @client_data['switches']['alerts']['recipient_override']['recipients']
    end

    def sqs_message_body(options = {})
      alert = options[:alert]
      item_id = options[:item_id]
      item_data = options[:item_data] || {}
      client_data = options[:client_data] || {}

      items = alert.trackers.map(&:item)
      item = item_id ? items.find { |i| i[:id].to_s == item_id.to_s } : items.first

      categories = get_message_categories(alert.template)

      locals = get_locals(
        { alert: alert,
          item: item,
          item_id: item_id,
          uuid: client_data['uuid'] }
      )

      subject = build_subject(
        { template: alert.template,
          client: alert.user.client_identifier,
          item: item,
          item_count: items.count }
      )

      data = {
        'ams_alert_id' => alert.id.to_s,
        'ams_categories' => categories,
        'ams_client_id' => alert.user.client_identifier.downcase,
        'ams_user_id' => alert.user.id,
        'ams_item_url' => item_data['item_url'],
        'ams_matches_list' => alert.matches.map(&:name).join(','),
        'ams_sg_user' => client_data['sg_username'],
        'ams_sg_pass' => client_data['sg_password'],
        'ams_to' => options[:recipient],
        'ams_version' => 1,

        'client_name' => client_data['name'],
        'client_logo' => client_data['logo_url'],
        'client_website_url' => client_data['website_url'],
        'manage_alerts_enabled' => client_data['manage_alerts_enabled'],

        'method' => 'post',
        'path' => '/',
        'service_url' => ::TRACKIF_TEMPLATING_URL,
        'tpl_client_identifier' => alert.user.client_identifier.downcase,
        'tpl_rules_engine' => 'erb',
        'tpl_rules_engine_parameters' => {
          'locals' => locals
        },
        'tpl_template_name' => alert.template,
        'uuid' => options[:uuid]
      }

      # must happen before subject is set
      data.merge!(client_data['email_data'] || {})

      data['ams_subject'] = subject

      data
    end

    def send_sqs_message(message_options = {})
      options = {
        'queue'        => templating_queue,
        'message_body' => sqs_message_body(message_options)
      }
      ::Service::SQS::MessageSender.new(options).call

      ::Service::FluentLogger.stream_logs(
        event:           'request',
        event_message:   'alert_created',
        event_status:    'success',
        uuid:            options['message_body']['uuid'],
        client:          options['message_body']['ams_client_id'],
        user_id:         options['message_body']['ams_user_id'],
        alert_id:        options['message_body']['ams_alert_id'],
        alert_template:  options['message_body']['tpl_template_name'],
        categories:      options['message_body']['ams_categories'],
        matches_list:    options['message_body']['ams_matches_list'],
        item_url:        options['message_body']['ams_item_url'],
        queue:           options['queue']
      )
    end

    def templating_queue
      client_identifier = @alert.user.client_identifier.downcase
      if client_identifier == 'client5'
        QUEUE_DIGEST
      else
        QUEUE
      end
    end

    def get_locals(options = {})
      alert = options[:alert]
      item = options[:item]

      locals = {
        'logo_url'          => true,
        'custom_css'        => '',
        'user_email'        => URI.encode_www_form([alert.user.user_identifier]),
        'client_identifier' => alert.user.client_identifier,
        'client_uuid'       => options[:uuid]
      }
      locals['item_key'] = URI.encode_www_form([item.url]) if item

      match = item ? item.url.match(/registryId=([^&]*)/) : nil
      locals['registry_id'] = match ? match[1] : nil

      # TODO: not sure why we do this
      locals['promo_code'] = '' if alert.template == 'now_tracking'

      # use item_id instead of item since item will default to first item
      item_data = get_locals_items(alert, options[:item_id])
      locals['items'] = item_data if item_data

      locals
    end

    def get_locals_items(alert, item_id = nil)
      return if alert.template == 'new_user' # no item data

      item_data = alert.data['items']

      # normalize if we have match data
      item_data = normalize_data(item_data) unless alert.template == 'now_tracking' || alert.template == 'new_account'

      # use specific item_id if provided
      item_data = item_id ? { item_id => item_data[item_id] } : item_data
      item_data
    end

    def get_message_categories(template_name)
      case template_name.downcase
      when 'now_tracking'
        ['now-tracking']
      when 'new_account'
        ['new-user']
      when 'new_user'
        ['new-user']
      when 'new_jobs'
        ['new-jobs']
      when 'back_in_stock'
        ['back-in-stock']
      when 'price_drop'
        ['price-drops']
      when 'new_items'
        ['new-items']
      when 'recommendations'
        ['recommendations']
      when 'digest'
        ['digest']
      when 'sold'
        ['sold']
      else
        ['tracked-changes']
      end
    end

    def normalize_data(alert_items)
      normalized = {}
      alert_items.each do |item_key, item_data|
        price_changes = ::Service::Normalizer::PriceChange.new(item_data['matches']['registry_price_change']).call
        purchase      = ::Service::Normalizer::RegistryPurchase.new(item_data['matches']['registry_purchase']).call
        availability  = ::Service::Normalizer::RegistryAvailability.new(item_data['matches']['registry_availability']).call
        new_items     = ::Service::Normalizer::RegistryNewItem.new(item_data['matches']['registry_list_update']).call
        product_search_price_change = ::Service::Normalizer::ProductSearchPriceChange.new(item_data['matches']['product_search_price_change']).call
        product_search_list_update  = ::Service::Normalizer::ProductSearchListUpdate.new(item_data['matches']['product_search_list_update']).call

        data = {
          'registry_near_event_date'    => item_data['matches']['registry_near_event_date'],
          'registry_price_change'       => price_changes,
          'registry_availability'       => availability,
          'registry_purchase'           => purchase,
          'registry_list_update'        => new_items,
          'product_search_price_change' => product_search_price_change,
          'product_search_list_update'  => product_search_list_update,
          'product_price_change'        => item_data['matches']['product_price_change'],
          'product_discontinued'        => item_data['matches']['product_discontinued'],
          'product_availability'        => item_data['matches']['product_availability'],
          'product_permanent_out_of_stock' => item_data['matches']['product_permanent_out_of_stock'],
          'composite_product_availability' => item_data['matches']['composite_product_availability'],
          'composite_product_price_change' => item_data['matches']['composite_product_price_change'],
          'job_search_list_update'         => item_data['matches']['job_search_list_update'],
          'generic_list_update'            => item_data['matches']['generic_list_update']
        }.delete_if { |_key, value| !value || (value && value.empty?) }

        (3..data.keys.size).each { |i| data.delete(data.keys[i]) }

        normalized[item_key] = item_data.dup
        normalized[item_key]['matches'] = data
      end

      normalized
    end

    def build_subject(options = {})
      template = options[:template]
      client = options[:client]
      item = options[:item]
      item_count = options[:item_count] || 0

      # TODO: only do the current_record lookup when we actually need it
      title = item.current_record.data['data']['title'] if item && item.current_record

      standard = [
        'wldemo',
        'client1ace',
        'client1acedev',
        'client1atv',
        'client1atvdev',
        'client1grl',
        'client1grldev',
        'client1indian',
        'client1indiandev',
        'client1ranger',
        'client1rangerdev',
        'client1rzr',
        'client1rzrdev',
        'client1',
        'client1dev',
        'client1victory',
        'client1victorydev'
      ]

      alternative = [
        'client2',
        'client2dev'
      ]

      custlst = [
        'client3',
        'client3dev'
      ]

      client4 = [
        'client4',
        'client4dev'
      ]

      subject = if standard.include? client
                  case template
                  when 'now_tracking'
                    'You are now tracking this product!'
                  else
                    "Back In Stock Alert: #{title}"
                  end

                elsif alternative.include? client
                  case template
                  when 'now_tracking'
                    'Sign up Confirmation - In Stock Alerts'
                  else
                    "Back In Stock Alert! - #{title}"
                  end

                elsif custlst.include? client
                  if item_count > 1
                    'custlst Leather Alert'
                  else
                    "#{build_subject_line(template)} #{title}"
                  end

                elsif client4.include? client
                  case template
                  when 'now_tracking'
                    "You're signed up for Availability Alerts. We'll let you know . . ."
                  else
                    "#{title} is back in stock"
                  end

                elsif client == 'lastcall'
                  'New Arrivals from Your Favorite Designers'

                elsif template == 'recommendations'
                  "Alert regarding #{title}"

                elsif template == 'now_tracking'
                  "Now Tracking #{title}"
                elsif item
                  "#{title} has been updated"
                else
                  ''
                end

      subject
    end

    # Temporary hack 
    def build_subject_line(template)
      case template
      when 'product_price_change'
        'Price Drop Alert!'
      when 'product_availability'
        'Back In Stock Alert!'
      when 'product_preorder'
        'Pre-Order Alert!'
      when 'product_search_list_update'
        'New Products Alert!'
      else
        'Product Alert!'
      end
    end
  end
end
