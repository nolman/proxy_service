require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'forward_proxy'))

describe ForwardProxy do
  let(:err) { Proc.new { fail "API request failed" } }

  it 'convert the xml to a json representation' do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/xml/user/show/nolman', 'mapping[user_login]' => '//login'}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['user_login'].should == 'nolman'
      end
    end
  end

  it 'convert the xml inner text to a json representation if attr is blank' do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/xml/user/show/nolman', 
                                    'mapping[user_login][path]' => '//login',
                                    'mapping[user_login][attr]' => ''}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['user_login'].should == 'nolman'
      end
    end
  end

  it "convert xml attrs to a json representation" do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/xml/user/show/nolman', 
                                    'mapping[following-count-type][path]' => '//following-count', 
                                    'mapping[following-count-type][attr]' => 'type'}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['following-count-type'].should == 'integer'
      end
    end
  end

  it "convert xml attrs to an array json representation" do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/xml/user/show/nolman', 
                                    'mapping[following-count-type][][path]' => '//following-count', 
                                    'mapping[following-count-type][][attr]' => 'type'}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['following-count-type'].should == ['integer']
      end
    end
  end

  it 'convert the xml to an array json representation' do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://github.com/api/v2/xml/user/show/nolman', 'mapping[user_login][]' => '//login'}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['user_login'].should == ['nolman']
      end
    end
  end

  it 'follow one redirect' do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'http://google.com/', 'mapping[q]' => "title"}}, err) do |req|
        data = Yajl::Parser.parse(req.response)
        data['q'].should == "Google"
      end
    end
  end

  it "should forward a parsed request on and return that responses data" do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'https://github.com', :forward_to => 'http://www.google.com/search', 'mapping[q]' => "title"}}, err) do |req|
        doc = Nokogiri(req.response)
        req.response_header.keys.should include("CACHE_CONTROL")
        doc.at("title").inner_html.should include("GitHub - Google Search")
      end
    end
  end

  it "should preserve query params in original url" do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'https://github.com', :forward_to => 'http://www.google.com/search?q=foo', 'mapping[bar]' => "title"}}, err) do |req|
        doc = Nokogiri(req.response)
        doc.at("title").inner_html.should include("foo - Google Search")
      end
    end
  end

  it "should follow one redirect in the forward to url" do
    with_api(XmlAsJsonProxy) do
      get_request({:query => {:url => 'https://github.com', :forward_to => 'http://google.com/search', 'mapping[q]' => "title"}}, err) do |req|
        doc = Nokogiri(req.response)
        doc.at("title").inner_html.should_not include("301")
        doc.at("title").inner_html.should include("GitHub - Google Search")
      end
    end
  end

end
