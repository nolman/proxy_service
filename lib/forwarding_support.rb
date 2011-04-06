class ForwardingSupport
  def initialize(app)
    @app = app
  end

  def call(env)
    async_cb = env['async.callback']
    env['async.callback'] = Proc.new do |status, headers, body|
      async_cb.call(post_process(env, status, headers, body))
    end
    status, headers, body = @app.call(env)
    post_process(env, status, headers, body)
  end

  def post_process(env, status, headers, body)
    body = body.first if body.is_a?(Array)
    return [status, headers, body] unless env.params['forward_to']
    begin
      body = Yajl::Parser.parse(body) if body.is_a?(String)
      uri = Addressable::URI.parse(env.params['forward_to'])
      uri.query_values = (uri.query_values || {}).merge(body)
      http = EM::HttpRequest.new(uri).get(:redirects => 1)
      [200, http.response_header, http.response]
    rescue Exception => ex
      [status, headers, body]
    end
  end
end

class Fixnum
  def to_str
    self.to_s
  end
end
