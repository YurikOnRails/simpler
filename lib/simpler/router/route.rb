module Simpler
  class Router
    class Route
      PARAM_PATTERN = %r{:[^/]+}
      PATH_PARAM_MATCHER = %r{[^/]+}

      attr_reader :controller, :action, :params, :method, :path

      def initialize(method, path, controller, action)
        @method = method.to_sym
        @path = path.to_s.freeze
        @controller = controller
        @action = action.to_sym
        @params = {}.freeze
        @path_pattern = build_path_pattern
      end

      def match?(request_method, request_path)
        return false unless method_matches?(request_method)

        if (path_match = path_matches?(request_path))
          @params = extract_params(path_match)
          true
        else
          false
        end
      end

      private

      def method_matches?(request_method)
        @method == request_method.to_sym
      end

      def path_matches?(request_path)
        request_path.match(@path_pattern)
      end

      def build_path_pattern
        pattern = @path.gsub(PARAM_PATTERN) do |match|
          param_name = match[1..-1]
          "(?<#{param_name}>#{PATH_PARAM_MATCHER.source})"
        end

        /\A#{pattern}\z/
      end

      def extract_params(path_match)
        return {}.freeze if path_match.names.empty?

        path_match.names.zip(path_match.captures).to_h.transform_values(&:freeze).freeze
      end
    end
  end
end
