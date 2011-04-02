require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'proxy_server')

describe RequestProxy do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'simply proxy the request' do
    with_api(RequestProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/json/user/show/nolman'}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['user']['login'].should == 'nolman'
      end
    end
  end

  it 'handle missing url query param' do
    with_api(RequestProxy) do
      get_request({:query => {}}, err) do |req|
        req.response.should == '[:error, "Url identifier missing"]'
      end
    end
  end

  it 'follow one redirect' do
    with_api(RequestProxy) do
      get_request({:query => {:url => 'http://google.com/'}}, err) do |req|
        Nokogiri(req.response).at('title').inner_html.should_not include('301')
      end
    end
  end

end
