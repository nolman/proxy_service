require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'proxy_server')

describe XmlAsJsonProxy do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'convert the xml to a json representation' do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/xml/user/show/nolman', 'mapping[user][login]' => '//login'}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['user']['login'].should == 'nolman'
      end
    end
  end

end
