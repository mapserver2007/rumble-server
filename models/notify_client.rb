require 'uri'

class NotifyClient
  def https_start
    Net::HTTP.version_1_2
    https = Net::HTTP.new(@host, 443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    https.start { yield https }
  end

  def line_notify(message, token)
    uri = URI("https://notify-api.line.me/api/notify")
    @host = uri.host
    @path = uri.path

    request_body = {'message' => message}
    uri = URI.regexp.match(message)
    unless uri.nil?
      request_body['imageThumbnail'] = uri[0]
      request_body['imageFullsize'] = uri[0]
    end

    require 'pp'
    pp request_body

    request = Net::HTTP::Post.new(@path)
    request.set_form_data(request_body)
    request.add_field 'Authorization', "Bearer #{token}"

    res = https_start do |https|
      https.request(request)
    end

    {:status => res.code}.to_json
  end
end
