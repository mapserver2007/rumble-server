# -*- coding: utf-8 -*-
require 'line/bot'

class Messaging
  def initialize(signature)
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = Config["LINE_CHANNEL_SECRET"]
      config.channel_token = Config["LINE_CHANNEL_TOKEN"]
    }
    @signature = signature
  end

  def body=(message)
    @message = message
  end

  def send
    unless @client.validate_signature(@message, @signature)
      return {:success => false, :body => {:status => 400}}
    end

    events = @client.parse_events_from(@message)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          @client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          # Nothing to do
        when Line::Bot::Event::MessageType::Location
          p "test"
        end
      end
    end

    return {:success => true, :body => {:status => 200}}
  end
end
