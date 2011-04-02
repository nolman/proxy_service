require 'goliath'
require 'em-synchrony/em-http'
require 'nokogiri'

class XmlAsJsonProxy < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
  use Goliath::Rack::Validation::RequiredParam, {:key => 'url'}

  def response(env)
    http = EM::HttpRequest.new(params['url']).get(:redirects => 1)
    nested_params = ::Rack::Utils.parse_nested_query(env['QUERY_STRING'])
    document = Nokogiri(http.response)
    logger.info "Received #{http.response_header.status} from #{nested_params['url']}"
    render_with_forward_to_support(200, {'X-Goliath' => 'Proxy', 'Content-Type' => 'application/json'}, mapping_to_json(nested_params['mapping'], document))
  end

  def render_with_forward_to_support(code, headers, body)
    if params['forward_to']
      uri = Addressable::URI.parse(params['forward_to'])
      uri.query_values = (uri.query_values || {}).merge(body)
      http = EM::HttpRequest.new(uri).get(:redirects => 1)
      [200, http.response_header, http.response]
    else
      [code, headers, body]
    end
  end

  def mapping_to_json(mapping, document)
    {}.tap do |result|
      mapping.each do |key, value|
        if value.is_a?(Hash)
          result[key] = mapping_to_json(value, document)
        else
          result[key] = document.at(value).inner_html
        end
      end
    end
  end
end
