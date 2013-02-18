require 'addressable/uri'
require 'andand'
require 'charlock_holmes'
require 'json'
require 'rest-client'
require 'sinatra'

class App < Sinatra::Base
  get '/:method' do
    Request.new(self, params).handle_request
  end

  post '/:method' do
    Request.new(self, params).handle_request
  end
end

class Request
  attr_reader :context, :request_attributes, :response_attributes
  def initialize(context, params)
    @context = context
    @request_attributes = {
      url: params[:url].andand.strip,
      method: params[:method].andand.to_sym || :get,
      headers: params[:headers] || {},
      timeout: params[:timeout].andand.to_i || -1,
      open_timeout: params[:open_timeout].andand.to_i || 15,
    }
    @response_attributes = {
      force: params[:force].andand.strip,
      callback: params[:callback],
    }
  end

  def handle_request
    validate_request_attributes!
    request_attributes[:url] = Addressable::URI.parse(request_attributes[:url]).normalize.to_str
    response = RestClient::Request.execute(request_attributes)
    Response.send(context, response_attributes.merge(response: response))
  rescue => e
    if e.is_a?(RestClient::Exception)
      Response.send(context, response_attributes.merge(response: e.response))
    else
      message = "#{e.class.name}: #{e.message}"
      Response.send(context, response_attributes.merge(error: message))
    end
  end

  private

  def validate_request_attributes!
    unless [:get, :post, :put, :delete, :head, :patch].include?(request_attributes[:method])
      raise StandardError.new("Unsupported method: #{request_attributes[:method]}")
    end
    if request_attributes[:url].nil? || request_attributes[:url] == ""
      raise StandardError.new("No URL specified")
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
