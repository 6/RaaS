require 'sinatra'
require 'json'

class App < Sinatra::Base
  get '/:method' do
    content_type :json
    {:test => "response"}.to_json
  end
end
