require 'goliath'
require File.expand_path(File.join(File.dirname(__FILE__), 'forwarding_support'))
require 'em-synchrony/em-http'

class ForwardProxy < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format

  def response(env)
    http = EM::HttpRequest.new(params['url']).get(:redirects => 1)
    http = EM::HttpRequest.new(params['forward_to']).post(:body => {:document => http.response})
    [http.response_header.status, http.response_header, http.response]
  end
end
