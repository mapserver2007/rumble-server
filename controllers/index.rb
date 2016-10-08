require 'cgi'
require 'sinatra/json'

post '/notify' do
  client = NotifyClient.new
  puts client.line_notify(params[:text], params[:token])
end

not_found do
  json({:status => "404"})
end
