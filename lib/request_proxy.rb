require 'goliath'
require File.expand_path(File.join(File.dirname(__FILE__), 'forwarding_support'))
require 'em-synchrony/em-http'

class RequestProxy < Goliath::API
  use ForwardingSupport
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  use Goliath::Rack::Validation::RequiredParam, {:key => 'url'}

  def response(env)
    http = EM::HttpRequest.new(params['url']).get(:redirects => 1)
    logger.info "Received #{http.response_header.status} from #{params['url']}"
    [200, http.response_header, http.response]
  end
end
