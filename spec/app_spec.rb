#encoding: utf-8
require 'spec_helper'

describe 'app' do
  let(:params) { {url: "http://www.google.com"} }

  describe 'get' do
    it "calls Reques.handle with self and params" do
      expected_params = {
        'method' => 'put',
        'url' => params[:url]
      }

      Request.should_receive(:handle).with(kind_of(App), hash_including(expected_params))

      get "/put", params
    end
  end

  describe 'post' do
    it "calls Request.handle with self and params" do
      expected_params = {
        'method' => 'head',
        'url' => params[:url]
      }

      Request.should_receive(:handle).with(kind_of(App), hash_including(expected_params))

      post "/head", params
    end
  end

  context "with an invalid HTTP method" do
    before { post "/invalid", params }
    it "responds with 400" do
      last_response.status.should == 400
    end

    it "includes the corresponding error message" do
      response_json['error'].should include("Unsupported method")
    end
  end

  context "with a missing URL parameter" do
    before { post "/get", {} }
    it "responds with 400" do
      last_response.status.should == 400
    end

    it "includes the corresponding error message" do
      response_json['error'].should include("No URL specified")
    end
  end

  context "with an invalid URL" do
    before do
      stub_request(:get, "http://invalid").to_raise(SocketError)
      post "/get", {url: "http://invalid"}
    end

    it "responds with 400" do
      last_response.status.should == 400
    end

    it "includes SocketError in the error message" do
      response_json['error'].should include("SocketError")
    end
  end

  context "when a RestClient exception occurs" do
    context "if there is no response" do
      before do
        e = RestClient::Exception.new
        e.response = nil
        stub_request(:get, "http://uguu.xyz").to_raise(e)
        post "/get", {url: "http://uguu.xyz"}
      end

      it "responds with 400" do
        last_response.status.should == 400
      end

      it "includes an the corresponding error message" do
        response_json['error'].should include("RestClient exception without response")
      end
    end

    context "if there is a response" do
      before do
        stub_request(:get, "http://unyuu.xyz").to_return(
          :body =>  "<html><h1>404 not found</h1></html>",
          :status => 404,
        )
        post "/get", {url: "http://unyuu.xyz"}
      end

      it "responds with 200" do
        last_response.status.should == 200
      end

      it "includes the status code in the response JSON" do
        response_json['response']['status'].should == 404
      end

      it "includes the response body in the response JSON" do
        response_json['response']['body'].should include("404 not found")
      end
    end
  end

  context "when the remote site responds with 200" do
    before do
      stub_request(:get, "http://dokkyun.xyz").to_return(
        :body =>  "<html><h1>&lt;3</h1></html>",
        :status => 200,
      )
      post "/get", {url: "http://dokkyun.xyz"}
    end

    it "responds with 200" do
      last_response.status.should == 200
    end

    it "includes the status code in the response JSON" do
      response_json['response']['status'].should == 200
    end

    it "includes the response body in the response JSON" do
      response_json['response']['body'].should include("&lt;3")
    end
  end

  context "with the force parameter set" do
    let(:response_body) { "<html><h1>pon</h1></html>" }
    before(:each) do
      stub_request(:get, "http://ponpon.pon").to_return(
        :body =>  response_body,
        :status => 200,
      )
    end

    def go!
      post "/get", {url: "http://ponpon.pon", force: "Shift_JIS"}
    end

    it "never uses EncodingHelper" do
      EncodingHelper.should_not_receive(:detect)
      go!
    end

    it "converts from the forced parameter to UTF-8" do
      EncodingHelper.should_receive(:convert).with(
        string: response_body,
        from: "Shift_JIS",
        to: "UTF-8",
      )
      go!
    end
  end

  context "with an IDN as the URL" do
    it "converts the URL to punycode" do
      request = stub_request(:get, "http://xn--1xa.net")

      post "/get", {url: "http://π.net"}
      request.should have_been_requested
    end
  end
end
