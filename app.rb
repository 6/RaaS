require 'addressable/uri'
require 'andand'
require 'charlock_holmes'
require 'json'
require 'rest-client'
require 'sinatra'

class App < Sinatra::Base
  get '/:method' do
    Request.handle(self, params)
  end

  post '/:method' do
    Request.handle(self, params)
  end
end

module Request
  def self.handle(context, params)
    method = params[:method].andand.to_sym || :get
    headers = params[:headers] || {}
    timeout = params[:timeout].andand.to_i || -1
    open_timeout = params[:open_timeout].andand.to_i || 15
    attributes = {
      force: params[:force].andand.strip,
      callback: params[:callback],
    }
    unless [:get, :post, :put, :delete, :head, :patch].include?(method)
      return Response.send(context, attributes.merge(error: "Unsupported method: #{params[:method]}"))
    end
    if params[:url].nil? || params[:url].strip == ""
      return Response.send(context, attributes.merge(error: "No URL specified"))
    end
    url = Addressable::URI.parse(params[:url].strip).normalize.to_str
    begin
      response = RestClient::Request.execute(method: method, url: url, headers: headers, open_timeout: open_timeout, timeout: timeout)
      return Response.send(context, attributes.merge(response: response))
    rescue => e
      if e.is_a?(RestClient::Exception)
        return Response.send(context, attributes.merge(response: e.response))
      else
        return Response.send(context, attributes.merge(error: e.class.name))
      end
    end
  end
end

module EncodingHelper
  def self.detect(attributes = {})
    result = CharlockHolmes::EncodingDetector.detect(attributes[:string])
    if result[:encoding] && result[:confidence] >= (attributes[:confidence_cutoff] || 10)
      result[:encoding]
    else
      attributes[:default]
    end
  rescue
    attributes[:default]
  end

  def self.convert(attributes = {})
    attributes[:string].force_encoding(attributes[:from]).encode(attributes[:to])
  end
end

module Response
  def self.send(res, attributes = {})
    response = attributes[:response]
    if attributes[:error] || !response
      status_code = 400
      response_hash = nil
      attributes[:error] ||= "RestClient exception without response"  if !response
    else
      status_code = 200
      attributes[:force] ||= EncodingHelper.detect(string: response.body, default: "UTF-8")
      response_hash = {
        :status => response.code,
        :headers => response.headers,
        :cookies => response.cookies,
        :body => EncodingHelper.convert(string: response.body, from: attributes[:force], to: "UTF-8"),
      }
    end
    res.content_type :json
    res.status status_code
    json = {
      :error => attributes[:error],
      :response => response_hash,
    }.to_json
    json = "#{attributes[:callback]}(#{json})"  if attributes[:callback]
    json
  end
end
