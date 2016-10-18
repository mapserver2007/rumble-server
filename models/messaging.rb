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

  def api_dispatcher(token, text)
    case text
    when /([^0-9a-zA-Z]+)→([^0-9a-zA-Z\s]+)(?:\s*)(\u59CB\u767A){0,}(\u7D42\u96FB){0,}/i
      from, to, shihatu, shuden = $1, $2, $3, $4
      norikae = Norikae.new(from, to, shihatu, shuden)
      @client.reply_message(token, {type: 'text', text: norikae.search})
    when /(?:(.+)画像)(?:はよ|クレメンス|くれ)((?:\uFF01|!){0,})/i
      keyword, count = $1, $2 # TODO 回数
      tumblr = Tumblr.new
      res = tumblr.get_image(keyword)
      if res[:state] = 200
        # @client.reply_message(token, {type: 'text', text: res[:image]})
        hoge = "https://goo.gl/KpIbwJ"
        Logger.info res[:image]
        @client.reply_message(token, {type: 'image', originalContentUrl: hoge, previewImageUrl: hoge})
      else
        @client.reply_message(token, {type: 'text', text: res[:text]})
      end
    end
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
          api_dispatcher(event['replyToken'], event.message['text'].force_encoding("UTF-8"))
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          # Nothing to do
        when Line::Bot::Event::MessageType::Location
          # Yet implement ...
          # 位置情報から、「何を探しましょう？」的な会話を実装したい
        end
      end
    end

    return {:success => true, :body => {:status => 200}}
  end
end
