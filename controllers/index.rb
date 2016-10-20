require 'sinatra/json'

post '/callback' do
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  messaging = Messaging.new(signature)
  messaging.body = request.body.read
  result = messaging.send

  unless params[:postback_delete_image].nil?
    Logger.info params
  end

  if result[:success]
    json(result[:body])
  else
    error json(result[:body])
  end
end

post '/notify' do
  client = NotifyClient.new
  puts client.line_notify(params[:text], params[:token])
end

not_found do
  json({:status => "404"})
end
