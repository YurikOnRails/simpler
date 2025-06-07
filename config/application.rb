require_relative '../lib/simpler/middleware/logger'

class Application < Simpler::Application
  def initialize
    super
    use Simpler::Middleware::Logger
  end
end
