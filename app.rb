#
# Application.
#

module Service
  class App < Sinatra::Base
    #
    # Configuration.
    #
    configure do
      set :logging, nil # we want Logger middleware
      set :dump_errors, false # we'll handle error logging ourselves

      # workaround for Sinatra's special test behavior
      set :show_exceptions, (ENV['RACK_ENV'] == 'test' ? :after_handler : false)

      # use(Helpers::MyaLogger, Service::LoggerConsole)
    end

    helpers do
      def load_uuid!
        @uuid = TrackifMicroservices::MessageQueue.set_trackif_uuid_by_header(request.env)
      end

      def load_queue_message!
        request.body.rewind
        TrackifMicroservices::MessageQueue.receive_message(request.env, request.body.read, { force: true }) do |message|
          @queue_message = JSON.parse(message).merge({ 'uuid' => @uuid })

          @client_identifier = @queue_message['client_identifier'] if @queue_message
          @user_id = @queue_message['user_id'] if @queue_message
          @user_identifier = @queue_message['user_identifier'] if @queue_message
        end
      end

      def validate_schema!(endpoint)
        return unless SCHEMA_VALIDATION_ENABLED

        Trackif::Json::Schema::Validate.new({ endpoint: endpoint, data: @queue_message.to_json }).call
      end

      def request_time
        ((Time.now - @timer_start) * 1000).floor if @timer_start
      end
    end

    before do
      load_uuid!
      @timer_start = Time.now
    end

    after do
      timer = request_time

      if request_time > REQUEST_TIME_THRESHOLD
        ::Service::FluentLogger.stream_logs({
          event: 'debug',
          event_name: 'route_slow',
          uuid: @uuid,
          method: request.request_method,
          path: request.path,
          status: response.status,
          timer: timer,
          client_identifier: @client_identifier,
          user_id: @user_id
        })
      end
    end

    error do
      data = {
        event: 'exception',
        error: env['sinatra.error'].message,
        error_backtrace: env['sinatra.error'].backtrace,
        context: 'application_error'
      }
      ::Service::FluentLogger.stream_logs(data)

      payload = {
        event: 'exception',
        message: err.message,
        backtrace: err.backtrace,
        uuid: @uuid,
        method: request.request_method,
        path: request.path,
        status: response.status,
        timer: request_time,
        client: @client_identifier,
        user_id: @user_id
      }

      ::Service::FluentLogger.stream_logs(payload)

      status(500)
    end

    #
    # Health check.
    #
    get '/status' do
      body('')
      status(200)
    end

    #
    # Version
    #
    get '/version' do
      ret = { 'version' => Service::VERSION }
      body(ret.to_json)
      status(200)
    end

    #
    # Process request.
    #
    post '/' do
      load_queue_message!

      if @queue_message['klass'] == 'CacheInvalidation'
        ::Service::CACHE_STORE.clear
        return 200
      end

      validate_schema!('root')

      ::Service::FluentLogger.stream_logs(
        event:           'request_received_to_create_alert',
        uuid:            @uuid,
        client:          @client_identifier,
        user_id:         @user_id,
        user_identifier: @user_identifier,
        matches_names:   @queue_message['matches_names']
      )

      data = Service::AlertsGenerator.new(@queue_message).call

      return 500 unless data['status'] == 'success'

      return 200
    end
  end
end
