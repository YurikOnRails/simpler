require 'yaml'
require 'singleton'
require 'sequel'
require_relative 'router'
require_relative 'controller'

module Simpler
  class Application
    include Singleton

    DEFAULT_SEQUEL_EXTENSIONS = %i[pagination query_literals].freeze

    attr_reader :db, :router, :middleware

    def initialize
      @router = Router.new
      @middleware = []
      @db = nil
    end

    def bootstrap!
      setup_database
      require_app
      require_routes
    end

    def routes(&block)
      router.instance_eval(&block)
    end

    def call(env)
      route = router.route_for(env)
      env['simpler.route'] = route
      controller = route.controller.new(env)
      action = route.action

      make_response(controller, action)
    rescue Router::RouteNotFoundError => e
      make_not_found_response(e)
    rescue StandardError => e
      make_error_response(e)
    end

    def use(middleware_class, *args)
      middleware << proc { |app| middleware_class.new(app, *args) }
    end

    def to_app
      return @app if @app

      builder = Rack::Builder.new
      apply_middleware(builder)
      builder.run(self)
      @app = builder.to_app
    end

    private

    def require_app
      Dir[File.join(Simpler.root, 'app', '**', '*.rb')].sort.each { |file| require file }
    end

    def require_routes
      require Simpler.root.join('config/routes')
    end

    def setup_database
      database_config = load_database_config
      @db = Sequel.connect(database_config)
      setup_database_extensions
    end

    def load_database_config
      config = YAML.safe_load(
        File.read(Simpler.root.join('config/database.yml')),
        permitted_classes: [Symbol]
      )
      config['database'] = Simpler.root.join(config['database'])
      config
    end

    def setup_database_extensions
      DEFAULT_SEQUEL_EXTENSIONS.each { |ext| @db.extension(ext) }
    end

    def apply_middleware(builder)
      middleware.each { |m| builder.use(m) }
    end

    def make_response(controller, action)
      controller.make_response(action)
    end

    def make_not_found_response(error)
      [
        404,
        { 'Content-Type' => 'text/plain' },
        ["404 Not Found\n\n#{error.message}"]
      ]
    end

    def make_error_response(error)
      log_error(error)
      [
        500,
        { 'Content-Type' => 'text/plain' },
        ["500 Internal Server Error\n\n#{error.message}"]
      ]
    end

    def log_error(error)
      logger = Logger.new(Simpler.root.join('log/errors.log'))
      logger.error(error.message)
      logger.error(error.backtrace.join("\n"))
    end
  end
end
