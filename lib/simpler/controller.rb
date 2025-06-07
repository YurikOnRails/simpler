require_relative 'view'

module Simpler
  class Controller
    class DoubleRenderError < StandardError; end

    CONTENT_TYPES = {
      plain: 'text/plain',
      json: 'application/json',
      xml: 'application/xml',
      html: 'text/html'
    }.freeze

    attr_reader :name, :request, :response

    def initialize(env)
      @name = extract_name
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
      @render_performed = false
    end

    def make_response(action)
      set_request_context(action)
      set_default_headers
      process_action(action)
      ensure_response_written

      @response.finish
    end

    protected

    def params
      @params ||= begin
        request_params = @request.params
        route_params = @request.env['simpler.route']&.params || {}
        request_params.merge(route_params)
      end
    end

    def render(template_or_options)
      ensure_not_rendered
      handle_render_options(template_or_options)
      write_response
    end

    def status(code)
      @response.status = code.to_i
    end

    def headers
      @response.headers
    end

    private

    def extract_name
      self.class.name.match('(?<n>.+)Controller')[:n].downcase
    end

    def set_request_context(action)
      @request.env['simpler.controller'] = self
      @request.env['simpler.action'] = action
    end

    def set_default_headers
      headers['Content-Type'] = CONTENT_TYPES[:html]
    end

    def process_action(action)
      send(action)
    end

    def ensure_response_written
      write_response unless @render_performed
    end

    def ensure_not_rendered
      raise DoubleRenderError, 'Cannot render or redirect more than once per action' if @render_performed
    end

    def handle_render_options(template_or_options)
      case template_or_options
      when String, Symbol
        @request.env['simpler.template'] = template_or_options
      when Hash
        @render_options = template_or_options
      end
    end

    def write_response
      return if @render_performed

      body = render_body
      @response.write(body)
      @render_performed = true
    end

    def render_body
      if @render_options
        process_render_options
      else
        render_template
      end
    end

    def render_template
      View.new(@request.env).render(binding)
    end

    def process_render_options
      render_type, content = @render_options.first
      return render_template unless CONTENT_TYPES.key?(render_type)

      headers['Content-Type'] = CONTENT_TYPES[render_type]
      format_response_body(render_type, content)
    end

    def format_response_body(type, content)
      case type
      when :json then content.to_json
      when :xml  then content.to_xml
      else content.to_s
      end
    end
  end
end
