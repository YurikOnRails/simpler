require 'logger'
require 'forwardable'

module Simpler
  module Middleware
    class Logger
      extend Forwardable

      LOG_FORMAT = '%<time>s [%<level>s] %<message>s\n'.freeze
      DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S.%L'.freeze

      def_delegators :@logger, :debug, :info, :warn, :error, :fatal

      def initialize(app, log_path = nil)
        @app = app
        @logger = create_logger(log_path)
      end

      def call(env)
        request_started_at = Time.now
        request_params = extract_request_params(env)

        log_request(env, request_params)
        status, headers, body = @app.call(env)
        log_response(env, status, headers, calculate_duration(request_started_at))

        [status, headers, body]
      end

      private

      def create_logger(log_path)
        log_path ||= Simpler.root.join('log/app.log')
        logger = ::Logger.new(log_path)
        logger.formatter = method(:format_log_message)
        logger
      end

      def format_log_message(severity, time, _, message)
        format(
          LOG_FORMAT,
          time: time.strftime(DATETIME_FORMAT),
          level: severity,
          message: message
        )
      end

      def extract_request_params(env)
        request = Rack::Request.new(env)
        route = env['simpler.route']

        request.params.merge(route&.params || {})
      end

      def log_request(env, params)
        info(build_request_message(env, params))
      end

      def log_response(env, status, headers, duration)
        info(build_response_message(env, status, headers, duration))
      end

      def build_request_message(env, params)
        method = env['REQUEST_METHOD']
        path = env['PATH_INFO']
        query = env['QUERY_STRING']
        route = env['simpler.route']

        message_parts = []
        message_parts << "Request: #{method} #{path}"
        message_parts << "?#{query}" if query.present?
        message_parts << "\nHandler: #{format_handler(route)}"
        message_parts << "\nParameters: #{params.inspect}"

        message_parts.join
      end

      def build_response_message(env, status, headers, duration)
        [
          format_response_status(status, headers, env),
          format_duration(duration),
          "\n"
        ].join("\n")
      end

      def format_handler(route)
        return 'None' unless route

        "#{route.controller}##{route.action}"
      end

      def format_response_status(status, headers, env)
        template = env['simpler.template']
        template_info = template ? " #{template}.html.erb" : ''
        status_text = Rack::Utils::HTTP_STATUS_CODES[status]

        "Response: #{status} #{status_text} [#{headers['Content-Type']}]#{template_info}"
      end

      def format_duration(duration)
        format('Duration: %.2fms', duration)
      end

      def calculate_duration(start_time)
        ((Time.now - start_time) * 1000).round(2)
      end
    end
  end
end
