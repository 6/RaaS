require 'addressable/uri'
require 'andand'
require 'charlock_holmes'
require 'json'
require 'rest-client'
require 'sinatra'
Dir.glob("./lib/*.rb").each do |file|
  require file
end

class App < Sinatra::Base
  get '/:method' do
    Request.new(self, params).handle_request
  end

  post '/:method' do
    Request.new(self, params).handle_request
  end
end
