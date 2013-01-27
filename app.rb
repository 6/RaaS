require 'addressable/uri'
require 'andand'
require 'charlock_holmes'
require 'json'
require 'rest-client'
require 'sinatra'

class App < Sinatra::Base
  get '/:method' do
    RequestHandler.go(self, params)
  end

  post '/:method' do
    RequestHandler.go(self, params)
  end
end

module RequestHandler
  def self.go(context, params)
    method = params[:method].andand.to_sym || :get
    forced_encoding = params[:force].andand.strip
    unless [:get, :post, :put, :delete, :head, :patch].include?(method)
      return Response.send(context, error: "Unsupported method: #{params[:method]}")
    end
    if params[:url].nil? || params[:url].strip == ""
      return Response.send(context, error: "No URL specified")
    end
    url = Addressable::URI.parse(params[:url].strip).normalize.to_str
    begin
      response = Request.send(url: url, method: method)
      return Response.send(context, response: response, force: forced_encoding)
    rescue => e
      if e.is_a?(RestClient::Exception)
        return Response.send(context, response: e.response)
      else
        return Response.send(context, error: e.class.name)
      end
    end
  end
end

module Request
  def self.send(attributes = {})
    RestClient::Request.execute(method: attributes[:method], url: attributes[:url])
  end
end

module EncodingDetector
  def self.detect(attributes = {})
    result = CharlockHolmes::EncodingDetector.detect(attributes[:string])
    if result[:confidence] >= (attributes[:confidence_cutoff] || 10)
      result[:encoding]
    else
      attributes[:default]
    end
  rescue
    attributes[:default]
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
      attributes[:force] ||= EncodingDetector.detect(string: response.body, default: "UTF-8")
      response_hash = {
        :status => response.code,
        :headers => response.headers,
        :cookies => response.cookies,
        :body => response.body.force_encoding(attributes[:force]).encode("UTF-8"),
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
