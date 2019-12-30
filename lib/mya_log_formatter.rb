require 'logger'
module Helpers
  # Format logs for CloudWatch Logs viewing and streaming
  class MyaLogFormatter < Logger::Formatter
    def call(level, timestamp, source, object)
      payload = if object.is_a?(Exception)
                  {
                    event: 'exception',
                    message: object.message,
                    backtrace: object.backtrace
                  }
                elsif object.is_a?(Hash)
                  object
                else
                  {
                    event: object
                  }
                end

      payload[:timestamp] ||= timestamp
      payload[:level] ||= level
      payload[:source] ||= source
      payload[:app_env] ||= ENV['RACK_ENV']
      payload[:log_index] ||= LOGGER_INDEX
      payload[:app_name]  ||= EB_APP_NAME
      payload[:env_name]  ||= EB_ENV_NAME

      if payload[:backtrace] && payload[:backtrace].is_a?(Array)
        payload[:backtrace] = payload[:backtrace].slice(0, 5)
        payload[:backtrace] = payload[:backtrace].join("\n")
      end

      format(payload)
    end

    private

    def format_time(time)
      time.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
    end

    def format_payload(message)
      if message.is_a?(Hash)
        # don't pretty print or it messes up CloudWatch Logs formatting
        message.compact.to_json
      else
        message
      end
    end

    def format(payload)
      # order is required by CloudWatch stream hook
      output = [
        'LOG',
        format_time(payload[:timestamp]),
        payload[:log_index], # kibana index prefix
        payload[:app_name],  # kibana type
        (payload[:level] || 'DEBUG').upcase,
        payload[:event],
        format_payload(payload)
      ]

      output.join(' ') + "\n"
    end
  end
end
