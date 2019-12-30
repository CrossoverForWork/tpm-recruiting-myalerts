module Service
  # Public: Service for sending an alert.
  class AlertSender
    def initialize(options)
      @options = options
      @alert_id     = options['alert_id']
      @notification = options['notification']
      @response     = { 'status'  => 'failure',
                        'message' => nil,
                        'data'    => {} }
      @client_data = options['client_data']
      @uuid = options['uuid']

      @alert        = nil
      @item         = nil
      @match_id     = nil
      @tracker_id   = nil
      @tracker      = nil
      @user         = nil
    end

    def self.build(options)
      case options['notification'].downcase
      when 'email'
        EmailAlertSender.new(options)
      when 'external'
        ExternalAlertSender.new(options)
      when 'sms'
        SmsSender.new(options)
      end
      # TODO: handle unknown notification type
    end
  end
end
