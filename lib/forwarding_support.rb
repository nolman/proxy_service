module ForwardingSupport

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

end
