require 'addressable/uri'
require 'andand'
require 'json'
require 'rest-client'
require 'sinatra'
# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class App < Sinatra::Base
  def go
    method = params[:method].andand.to_sym || :get
    forced_encoding = params[:force].andand.strip
    unless [:get, :post, :put, :delete, :head, :patch].include?(method)
      return Response.send(self, error: "Unsupported method: #{params[:method]}")
    end
    if params[:url].nil? || params[:url].strip == ""
      return Response.send(self, error: "No URL specified")
    end
    url = Addressable::URI.parse(params[:url].strip).normalize.to_str
    begin
      response = Request.send(url: url, method: method)
      return Response.send(self, response: response, force: forced_encoding)
    rescue SocketError => e
      return Response.send(self, error: "SocketError. Unable to connect to URL.")
    rescue URI::InvalidURIError => e
      return Response.send(self, error: "URI::InvalidURIError")
    rescue Encoding::UndefinedConversionError => e
      return Response.send(self, error: "Encoding::UndefinedConversionError")
    rescue => e
      if e.is_a?(RestClient::Exception)
        return Response.send(self, response: e.response)
      else
        return Response.send(self, error: "Invalid params")
      end
    end
  end

  get '/:method' do
    go
  end

  post '/:method' do
    go
  end
end

module Request
  def self.send(attributes = {})
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
      body = if attributes[:force]
        response.body.force_encoding(attributes[:force]).encode("UTF-8")
      else
        response.body.encode("UTF-8")
      end
      response_hash = {
        :status => response.code,
        :headers => response.headers,
        :cookies => response.cookies,
        :body => body,
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
