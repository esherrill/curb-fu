require File.dirname(__FILE__) + '/../../../spec_helper'
require 'curb'

def regex_for_url_with_params(url, *params)
  regex = '^' + url.gsub('/','\/').gsub('.','\.')
  regex += '\?' unless params.empty?

  unless params.empty?
    param_possibilities = params.join('|')
    regex += params.inject([]) { |list, param| list << "(#{param_possibilities})" }.join('&')
  end
  regex += '$'
  Regexp.new(regex)
end

class TestHarness
  extend CurbFu::Request::Base
  
  def self.create_post_fields(*args)   # testing interface to private method #create_post_fields
    super(*args)
  end
  
  def self.create_put_fields(*args)   # testing interface to private method #create_put_fields
    super(*args)
  end
end

describe CurbFu::Request::Base do
  describe "build_url" do
    it "should return a string if a string parameter is given" do
      TestHarness.build_url("http://www.cliffsofinsanity.com").should == "http://www.cliffsofinsanity.com"
    end
    it "should return a string if a :url paramter is given" do
      TestHarness.build_url(:url => "http://www.cliffsofinsanity.com", :headers => { 'Content-Type' => 'cash/dollars' }).should == "http://www.cliffsofinsanity.com"
    end
    it "should return a built url with just a hostname if only the hostname is given" do
      TestHarness.build_url(:host => "poisonedwine.com").should == "http://poisonedwine.com"
    end
    it "should return a built url with hostname and port if port is also given" do
      TestHarness.build_url(:host => "www2.giantthrowingrocks.com", :port => 8080).
        should == "http://www2.giantthrowingrocks.com:8080"
    end
    it "should return a built url with hostname, port, and path if all are given" do
      TestHarness.build_url(:host => "spookygiantburningmonk.org", :port => 3000, :path => '/standing/in/a/wheelbarrow.aspx').
        should == "http://spookygiantburningmonk.org:3000/standing/in/a/wheelbarrow.aspx"
    end
    it 'should append a query string if a query params hash is given' do
      TestHarness.build_url('http://navyseals.mil', :swim_speed => '2knots').
        should == 'http://navyseals.mil?swim_speed=2knots'
    end
    it 'should append a query string if a query string is given' do
      TestHarness.build_url('http://chocolatecheese.com','?nuts=true').
        should == 'http://chocolatecheese.com?nuts=true'
    end
    it "should accept a 'protocol' parameter" do
      TestHarness.build_url(:host => "mybank.com", :protocol => "https").should == "https://mybank.com"
    end
  end

  describe "get" do
    it "should get the google" do
      @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil)
      Curl::Easy.should_receive(:new).with('http://www.google.com').and_return(@mock_curb)
      
      TestHarness.get("http://www.google.com")
    end
    it "should return a 404 code correctly" do
      mock_curb = mock(Object, :http_get => nil)
      TestHarness.stub!(:build).and_return(mock_curb)
      mock_response = mock(CurbFu::Response::NotFound, :status => 404)
      CurbFu::Response::Base.stub!(:from_curb_response).and_return(mock_response)
      
      TestHarness.get("http://www.google.com/ponies_and_pirates").should == mock_response
    end
    it "should append query parameters" do
      @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil)
      Curl::Easy.should_receive(:new).with(regex_for_url_with_params('http://www.google.com', 'search=MSU\+vs\+UNC', 'limit=200')).and_return(@mock_curb)
      TestHarness.get('http://www.google.com', { :search => 'MSU vs UNC', :limit => 200 })
    end
    it "should set cookies" do
      the_cookies = "SekretAuth=123134234"
      
      @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil)
      Curl::Easy.should_receive(:new).and_return(@mock_curb)
      @mock_curb.should_receive(:cookies=).with(the_cookies)
      
      TestHarness.get("http://google.com", {}, the_cookies)
    end

    describe "with_hash" do
      it "should get google from {:host => \"www.google.com\", :port => 80}" do
        @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil)
        Curl::Easy.should_receive(:new).with('http://www.google.com:80').and_return(@mock_curb)
      
        TestHarness.get({:host => "www.google.com", :port => 80})
      end
      it "should set authorization username and password if provided" do
        @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil, :http_auth_types= => nil)
        Curl::Easy.stub!(:new).and_return(@mock_curb)
        @mock_curb.should_receive(:userpwd=).with("agent:donttellanyone")
      
        TestHarness.get({:host => "secret.domain.com", :port => 80, :username => "agent", :password => "donttellanyone"})
      end
      it "should append parameters to the url" do
        @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil)
        Curl::Easy.should_receive(:new).with(regex_for_url_with_params('http://www.google.com', 'search=MSU\+vs\+UNC', 'limit=200')).and_return(@mock_curb)
        TestHarness.get({ :host => 'www.google.com' }, { :search => 'MSU vs UNC', :limit => 200 })
      end
      it "should set cookies" do
        the_cookies = "SekretAuth=123134234"

        @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil, :http_get => nil)
        Curl::Easy.should_receive(:new).and_return(@mock_curb)
        @mock_curb.should_receive(:cookies=).with(the_cookies)

        TestHarness.get({
          :host => "google.com",
          :port => 80,
          :cookies => the_cookies
        })
      end
    end
  end

  describe "post" do
    before(:each) do
      @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil)
      Curl::Easy.stub!(:new).and_return(@mock_curb)
    end

    it "should send each parameter to Curb#http_post" do
      @mock_q = Curl::PostField.content('q','derek')
      @mock_r = Curl::PostField.content('r','matt')
      TestHarness.stub!(:create_post_fields).and_return([@mock_q,@mock_r])

      @mock_curb.should_receive(:http_post).with(@mock_q,@mock_r)

      response = TestHarness.post(
        {:host => "google.com", :port => 80, :path => "/search"},
        { 'q' => 'derek', 'r' => 'matt' })
    end
  end
  
  describe "post_file" do
    it "should set encoding to multipart/form-data" do
      @cc = mock(Curl::PostField)
      Curl::PostField.stub!(:file).and_return(@cc)
      mock_curl = mock(Object, :http_post => nil)
      mock_curl.should_receive(:multipart_form_post=).with(true)
      TestHarness.stub!(:build).and_return(mock_curl)
      CurbFu::Response::Base.stub!(:from_curb_response)
      
      TestHarness.post_file('http://example.com', {'gelato' => 'peanut butter'}, 'cc_pic' => '/images/credit_card.jpg')
    end
    it "should post with file fields" do
      @cc = mock(Curl::PostField)
      Curl::PostField.should_receive(:file).and_return(@cc)
      mock_curl = mock(Object, :multipart_form_post= => nil, :http_post => nil)
      TestHarness.stub!(:build).and_return(mock_curl)
      CurbFu::Response::Base.stub!(:from_curb_response)
      
      TestHarness.post_file('http://example.com', {'gelato' => 'peanut butter'}, 'cc_pic' => '/images/credit_card.jpg')
    end
    it "should offer more debug information about CurlErrInvalidPostField errors" do
      @cc = mock(Curl::PostField)
      Curl::PostField.should_receive(:file).and_return(@cc)
      mock_curl = mock(Object, :multipart_form_post= => nil)
      mock_curl.stub!(:http_post).and_raise(Curl::Err::InvalidPostFieldError)
      TestHarness.stub!(:build).and_return(mock_curl)
      CurbFu::Response::Base.stub!(:from_curb_response)
      
      lambda { TestHarness.post_file('http://example.com', {'gelato' => 'peanut butter'}, 'cc_pic' => '/images/credit_card.jpg') }.
        should raise_error(Curl::Err::InvalidPostFieldError)
    end
  end

  describe "put" do
    before(:each) do
      @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil)
      Curl::Easy.stub!(:new).and_return(@mock_curb)
    end

    it "should send each parameter to Curb#http_put" do
      Curl::Easy.should_receive(:new).with('http://google.com:80/search?q=derek&r=matt').and_return(@mock_curb)
      @mock_curb.should_receive(:http_put)

      response = TestHarness.put(
        {:host => "google.com", :port => 80, :path => "/search"},
        { 'q' => 'derek', 'r' => 'matt' })
    end
  end
  
  describe "delete" do
    before(:each) do
      @resource_link = 'http://example.com/resource/1'
      @mock_curb = mock(Curl::Easy, :headers= => nil, :headers => {}, :header_str => "", :response_code => 200, :body_str => 'yeeeah', :timeout= => nil)
      Curl::Easy.stub!(:new).and_return(@mock_curb)
    end

    it "should send each parameter to Curb#http_delete" do
      Curl::Easy.should_receive(:new).with(@resource_link).and_return(@mock_curb)
      @mock_curb.should_receive(:http_delete)

      response = TestHarness.delete(@resource_link)
    end
  end
  
  
  describe "create_post_fields" do
    it "should return the params if params is a string" do
      TestHarness.create_post_fields("my awesome data that I'm sending to you").
        should == "my awesome data that I'm sending to you"
    end
    it "should convert hash items into Curl::PostFields" do
      Curl::PostField.should_receive(:content).with('us','obama')
      Curl::PostField.should_receive(:content).with('de','merkel')
      TestHarness.create_post_fields(:us => 'obama', :de => 'merkel')
    end
    it "should handle params that contain arrays" do
      Curl::PostField.should_receive(:content).with('q','derek,matt')

      TestHarness.create_post_fields('q' => ['derek','matt'])
    end
    it "should handle params that contain any non-Array or non-String data" do
      Curl::PostField.should_receive(:content).with('q','1')

      TestHarness.create_post_fields('q' => 1)
    end
    it "should return an array of Curl::PostFields" do
      TestHarness.create_post_fields(:ice_cream => 'chocolate', :beverage => 'water').each do |field|
        field.should be_a_kind_of(Curl::PostField)
      end
    end
  end
  
  describe "create_put_fields" do
    it "should return the params if params is a string" do
      TestHarness.create_put_fields("my awesome data that I'm sending to you").
        should == "my awesome data that I'm sending to you"
    end
    
    it 'should handle multiple parameters' do
      TestHarness.create_put_fields(:rock => 'beatles', :rap => '2pac').split("&").
        should include("rock=beatles","rap=2pac")
    end
    
    it "should handle params that contain arrays" do
      TestHarness.create_put_fields('q' => ['derek','matt']).
        should == "q=derek,matt"
    end

    it "should handle params that contain any non-Array or non-String data" do
      TestHarness.create_put_fields('q' => 1).should == "q=1"
    end
  end
  
  describe "global_headers" do
    it "should use any global headers for every request" do
      TestHarness.global_headers = {
        'X-Http-Modern-Parlance' => 'Transmogrify'
      }
      
      mock_curl = mock(Object, :timeout= => 'sure', :http_get => 'uhuh', :response_code => 200, :header_str => 'yep: sure', :body_str => 'ok')
      Curl::Easy.stub!(:new).and_return(mock_curl)
      mock_curl.should_receive(:headers=).with('X-Http-Modern-Parlance' => 'Transmogrify')
      TestHarness.get('http://example.com')
    end
    it "should not keep temporary headers from previous requests" do
      TestHarness.global_headers = {
        'X-Http-Political-Party' => 'republican'
      }
      
      mock_curl = mock(Object, :timeout= => 'sure', :http_get => 'uhuh', :response_code => 200, :header_str => 'yep: sure', :body_str => 'ok')
      Curl::Easy.stub!(:new).and_return(mock_curl)
      mock_curl.stub!(:headers=)
      
      TestHarness.get(:host => 'example.com', :headers => { 'Content-Type' => 'cash/dollars' })
      
      mock_curl.should_not_receive(:headers=).with(hash_including('Content-Type' => 'cash/dollars'))
      TestHarness.get('http://example.com')
      TestHarness.global_headers.should_not include('Content-Type' => 'cash/dollars')  # leave no trace!
    end
  end
end
