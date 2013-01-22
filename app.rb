require 'andand'
require 'json'
require 'rest-client'
require 'sinatra'
# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class App < Sinatra::Base
  get '/:method' do
    method = params[:method].andand.to_sym || :get
    unless [:get, :post, :put, :delete, :head, :patch].include?(method)
      return Response.send(self, error: "Unsupported method: #{params[:method]}")
    end
    if params[:url].nil? || params[:url].strip == ""
      return Response.send(self, error: "No URL specified")
    end
    begin
      response = RestClientWrapper.request(url: params[:url], method: method)
      return Response.send(self, response: response)
    rescue => e
      if e.is_a?(RestClient::Exception)
        return Response.send(self, response: e.response)
      else
        return Response.send(self, error: "Invalid params")
      end
    end
  end
end

module RestClientWrapper
  def self.request(attributes = {})
    RestClient::Request.execute(method: attributes[:method], url: attributes[:url])
  end
end

module Response
  def self.send(res, attributes = {})
    response = attributes[:response]
    if attributes[:error] || !response
      status_code = 400
      response_hash = nil
    else
      status_code = 200
      response_hash = {
        :status => response.code,
        :headers => response.headers,
        :cookies => response.cookies,
        :body => response.force_encoding("UTF-8").to_str,
      }
    end
    res.content_type :json
    res.status status_code
    {
      :error => attributes[:error],
      :response => response_hash,
    }.to_json
  end
end
