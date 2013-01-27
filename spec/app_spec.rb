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
end
