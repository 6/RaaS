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
    Response.new(context, response_attributes.merge(response: response)).handle_response
  rescue => e
    if e.is_a?(RestClient::Exception)
      Response.new(context, response_attributes.merge(response: e.response)).handle_response
    else
      error = {
        name: e.class.name,
        message: e.message,
      }
      Response.new(context, response_attributes.merge(error: error)).handle_response
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

class Response
  attr_reader :context, :attributes, :response, :error
  def initialize(context, attributes = {})
    @context = context
    @attributes = attributes
    @response = attributes[:response]
    if attributes[:error] || !@response
      @error = attributes[:error] || {}
      @error[:message] ||= "RestClient exception without response"  if !@response
    end
  end

  def handle_response
    if error
      response_hash = nil
    else
      response_hash = {
        status: response.code,
        headers: response.headers,
        cookies: response.cookies,
        body: utf8_response_body,
      }
    end
    context.content_type(:json)
    context.status(status_code)
    json = {
      error: error,
      response: response_hash,
    }.to_json
    json = "#{attributes[:callback]}(#{json})"  if attributes[:callback]
    json
  end

  private

  def status_code
    error ? 400 : 200
  end

  def utf8_response_body
    attributes[:force] ||= EncodingHelper.detect(string: response.body, default: "UTF-8")
    EncodingHelper.convert(string: response.body, from: attributes[:force], to: "UTF-8")
  end
end
