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
