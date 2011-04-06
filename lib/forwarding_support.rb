module ForwardingSupport

  def with_forward_to_support(code, headers, body)
    if params['forward_to']
      begin
        body = Yajl::Parser.parse(body) if body.is_a?(String)
        uri = Addressable::URI.parse(params['forward_to'])
        uri.query_values = (uri.query_values || {}).merge(body)
        http = EM::HttpRequest.new(uri).get(:redirects => 1)
        [200, http.response_header, http.response]
      rescue Exception => ex
        [code, headers, body]
      end
    else
      [code, headers, body]
    end
  end

end

class Fixnum
  def to_str
    self.to_s
  end
end
