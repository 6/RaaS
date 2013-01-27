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
      response_json = JSON.parse(last_response.body)

      response_json['error'].should include("Unsupported method")
    end
  end

  context "with a missing URL parameter" do
    before { post "/get", {} }
    it "responds with 400" do
      last_response.status.should == 400
    end

    it "includes the corresponding error message" do
      response_json = JSON.parse(last_response.body)

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
      response_json = JSON.parse(last_response.body)

      response_json['error'].should include("SocketError")
    end
  end
end
