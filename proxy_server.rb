require File.join(File.dirname(__FILE__), 'request_proxy')
require File.join(File.dirname(__FILE__), 'xml_as_json_proxy')

class ProxyServer < Goliath::API
  use Goliath::Rack::Params             # parse query & body params
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format
  use Goliath::Rack::ValidationError    # catch and render validation errors
 
  map "/proxy" do
    run RequestProxy.new
  end

  map "/as_json" do
    run XmlAsJsonProxy.new
  end

end
