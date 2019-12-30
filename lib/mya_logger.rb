module Helpers
  # Attach a logger to Sinatra / Rack
  class MyaLogger
    def initialize(app, logger)
      @app = app
      @logger = logger
    end

    def call(env)
      env['rack.logger'] ||= @logger
      @app.call(env)
    end
  end
end
