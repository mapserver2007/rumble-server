require 'sinatra/json'

before do
  headers 'Access-Control-Allow-Origin' => '*'
  headers 'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept'
end

get '/images/:name' do
  images = Images.new
  json(images.get_images(params[:name]))
end

post '/callback' do
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  messaging = Messaging.new(signature)
  messaging.body = request.body.read
  result = messaging.send

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
