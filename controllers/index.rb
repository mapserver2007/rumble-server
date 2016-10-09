require 'sinatra/json'

post '/callback' do
  Logger.info "kita-"

  norikae = Norikae.new
  norikae.search(request.body.read)


  # body = request.body.read
  # signature = request.env['HTTP_X_LINE_SIGNATURE']
  # messaging = Messaging.new(signature)
  # messaging.body = body
  # result = messaging.send
  #
  # if result[:success]
  #   json(result[:body])
  # else
  #   error json(result[:body])
  # end
end

post '/notify' do
  client = NotifyClient.new
  puts client.line_notify(params[:text], params[:token])
end

not_found do
  json({:status => "404"})
end
