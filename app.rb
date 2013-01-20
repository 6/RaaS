require 'sinatra'
require 'json'

get '/:method' do
  content_type :json
  {:test => "response"}.to_json
end
