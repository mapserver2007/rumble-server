# -*- coding: utf-8 -*-
require 'line/bot'

module DispatchType
  Reply = 1
  PostBack = 2
end

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

  def api_dispatcher(type, text)
    case type
    when DispatchType::Reply
      reply_at text
    when DispatchType::PostBack
      postback_at text
    end
  end

  def reply_at(text)
    case text
    when /([^0-9a-zA-Z]+)→([^0-9a-zA-Z\s]+)(?:\s*)(\u59CB\u767A){0,}(\u7D42\u96FB){0,}/i
      from, to, shihatu, shuden = $1, $2, $3, $4
      norikae = Norikae.new(from, to, shihatu, shuden)
      @client.reply_message(@token, {type: 'text', text: norikae.search})
    when /(?:(.+)画像)(?:はよ|クレメンス|くれ)((?:\uFF01|!){0,})/i
      keyword = $1
      count = $2.size.between?(1, 5) ? $2.size : 1
      tumblr = Tumblr.new
      res = tumblr.get_image(keyword, count)
      if res[:state] == 200
        columns = []
        res[:contents].each do |content|
          columns << {thumbnailImageUrl: content[:img], text: content[:text], actions: [
            {type: 'uri', label: '大きい画像を見る', uri: content[:img]},
            {type: 'postback', label: '二度と表示しない', data: 'action=delete&img=' + content[:img]}, # パラメータは適当
            {type: 'postback', label: '別人じゃねーか', data: 'action=move&img=' + content[:img]}
          ]}
        end

        @client.reply_message(@token, {
          type: 'template',
          altText: 'Don\'t support carousel.',
          template: {
            type: 'carousel',
            columns: columns
          }
        })
      else
        @client.reply_message(@token, {type: 'text', text: res[:text]})
      end
    end
  end

  def postback_at(text)

  end

  def send
    unless @client.validate_signature(@message, @signature)
      return {:success => false, :body => {:status => 400}}
    end

    events = @client.parse_events_from(@message)
    events.each do |event|
      @token = event['replyToken']
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          api_dispatcher(DispatchType::Reply, event.message['text'].force_encoding("UTF-8"))
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          # Nothing to do
        when Line::Bot::Event::MessageType::Location
          # Yet implement ...
          # 位置情報から、「何を探しましょう？」的な会話を実装したい
        end
      when Line::Bot::Event::Postback
        Logger.info event
      end
    end

    return {:success => true, :body => {:status => 200}}
  end
end
