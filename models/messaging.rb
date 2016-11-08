# -*- coding: utf-8 -*-
require 'line/bot'

module DispatchType
  Reply = 1
  PostBack = 2
end

module ActionType
  Up = "up"
  Down = "down"
end

module Command
  RumbleHelp = "h"
  TumblrImageInfo = "t"
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

  def command_dispatcher(cmd, text)
    case cmd
    when Command::RumbleHelp
      text = <<-"HELP"
【電車乗り換え】コマンド
(発車駅)→(到着駅) (終電|始発)

【声優画像取得】コマンド
(声優名またはあだ名)画像(はよ|くれ|クレメンス)(!{0,5})

【デバッグ用】コマンド
cmd.h ヘルプ
cmd.t.(声優名) 声優画像保存状況を通知
      HELP
      @client.reply_message(@token, {type: 'text', text: text.chomp})
    when Command::TumblrImageInfo
      tumblr = Tumblr.new
      info = tumblr.get_image_info(text)
      text_list = []
      text_list << "【#{text}】の画像数は#{info[:num]}"
      info[:info].each do |priority, num|
        text_list << "priorityが『#{priority}』の画像数は『#{num}』"
      end
      @client.reply_message(@token, {type: 'text', text: text_list.join("\n")})
    end
  end

  def reply_at(text)
    case text
    when /^cmd\.([a-z_-]+)(?:\.(.+)){0,1}/i
      command_dispatcher $1, $2
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
        urls = []
        id = nil
        res[:contents].each do |content|
          columns << {thumbnailImageUrl: content[:img], text: content[:text], actions: [
            {type: 'uri', label: '大きい画像を見る', uri: content[:img]},
            {type: 'postback', label: 'いいね！', data: "action=up&id=#{content[:id]}&img=#{content[:img]}"},
            {type: 'postback', label: 'この画像を表示しない', data: "action=down&id=#{content[:id]}&img=#{content[:img]}"}
          ]}
          urls << content[:img]
          id = content[:id] if id.nil?
        end

        tumblr.update_priority(id, urls, -1)

        @client.reply_message(@token, {
          type: 'template',
          altText: '画像を表示しました',
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
        tumblr = Tumblr.new
        query = URI::decode_www_form(event['postback']['data']).to_h

        case query['action']
        when ActionType::Up
          tumblr.update_priority(query['id'], query['img'], 1)
        when ActionType::Down
          tumblr.update_priority(query['id'], query['img'], 0, true)
        end
      end
    end

    return {:success => true, :body => {:status => 200}}
  end
end
