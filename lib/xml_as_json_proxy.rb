require 'goliath'
require File.expand_path(File.join(File.dirname(__FILE__), 'forwarding_support'))
require File.expand_path(File.join(File.dirname(__FILE__), 'document_converter'))
require 'em-synchrony/em-http'
require 'nokogiri'

class XmlAsJsonProxy < Goliath::API
  use ForwardingSupport
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  use Goliath::Rack::Validation::RequiredParam, {:key => 'url'}

  def response(env)
    http = EM::HttpRequest.new(params['url']).get(:redirects => 1)
    nested_params = ::Rack::Utils.parse_nested_query(env['QUERY_STRING'])
    logger.info "Received #{http.response_header.status} from #{nested_params['url']}"
    converter = DocumentConverter.new(Nokogiri(http.response),nested_params['mapping'])
    [200, {'X-Goliath' => 'Proxy', 'Content-Type' => 'application/json'}, converter.mapping_to_json]
  end

end
