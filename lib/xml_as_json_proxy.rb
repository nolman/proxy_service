require 'goliath'
require File.expand_path(File.join(File.dirname(__FILE__), 'forwarding_support'))
require 'em-synchrony/em-http'
require 'nokogiri'

class XmlAsJsonProxy < Goliath::API
  include ForwardingSupport
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
    with_forward_to_support(200, {'X-Goliath' => 'Proxy', 'Content-Type' => 'application/json'}, mapping_to_json(document, nested_params['mapping']))
  end

  def mapping_to_json(document, mapping)
    {}.tap do |result|
      mapping.each do |key, locator|
        result[key] = value_for(document, normalize_locator(locator))
      end
    end
  end

  def normalize_locator(locator)
    if locator.is_a?(Hash)
      locator
    elsif locator.is_a?(Array) && locator.first.is_a?(Hash)
      locator
    elsif locator.is_a?(Array) && !locator.first.is_a?(Hash)
      [{'path' => locator.first}]
    else
      {'path' => locator}
    end
  end

  def value_for(document, locator)
    if locator.is_a?(Array)
      locator = locator.first
      elements = document.search(locator['path'])
      elements.map {|element| get_value_for(element, locator) }
    else
      element = document.at(locator['path'])
      get_value_for(element, locator)
    end
  end

  def get_value_for(element, locator)
    if locator['attr'].to_s == ""
      element.inner_html
    else
      element[locator['attr']]
    end
  end

end
