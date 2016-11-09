# -*- coding: utf-8 -*-
require 'httpclient'
require 'uri'
require 'mechanize'

class Train
  TRANSFER_URL = 'http://www.jorudan.co.jp/norikae/cgi/nori.cgi'
  TRAIN_STATUS_URL = 'http://transit.yahoo.co.jp/traininfo/area/%s/'
  USERAGENT = "Mac Mozilla"

  attr_accessor :train_status

  def initialize
    @agent = create_agent
    @train_status = {}
  end

  def get_mapping_rules
    {
      '山の手線' => '山手線',
      '丸の内線' => '丸ノ内線',
      '埼京線' => '埼京川越線',
      '中央線' => '中央総武線',
      '京浜東北線' => '京浜東北根岸線',
      '常磐線' => '常磐線(各停)'
    }
  end

  def create_agent
    agent = Mechanize.new
    agent.user_agent_alias = USERAGENT
    agent.read_timeout = 10
    agent
  end

  def load_train_status(area, text)
    site = @agent.get(TRAIN_STATUS_URL % area)
    trainLines = (site/'//div[@class="labelSmall"]')
    trainLines.each do |elem|
      train_info = elem.next.next.search("tr")
      train_info.each do |tr|
        row = tr.search("td")
        next if row.empty?
        link = row.search("a").attribute("href").to_s

        alias_text = get_mapping_rules[text]
        text = alias_text unless alias_text.nil?

        train_name = row[0].inner_text
        unless train_name.index(text).nil?
          @train_status = {
            name: train_name,
            status: row[1].inner_text.gsub(/\[!\]/, ''),
            link: link,
            detail: ''
          }

          # 平常運転以外の場合、詳細情報を取得する
          unless row[1].xpath("span[@class='icnAlert']").empty?
            agent = create_agent
            site = agent.get(link)
            @train_status[:detail] = (site/'//dd[@class="trouble"]/p').inner_text
          end
        end
      end
    end
  end

  def transfer(from, to, shihatsu, shuden)
    type = {
      :cway => 0, :trainType => "乗り換え"
    }

    if !shihatsu.nil?
      type[:cway] = 2 # 始発
      type[:trainType] = shihatsu
    elsif !shuden.nil?
      type[:cway] = 3 # 終電
      type[:trainType] = shuden
    end

    url = "#{TRANSFER_URL}?Sok=1&eki1=#{URI.escape(from)}&eki2=#{URI.escape(to)}&type=t&Cway=#{type[:cway]}"
    response = HTTPClient.new.get_content(url)
    result = ""
    if /(■[\s\S]*?■.+)/ =~ response
      result = $1
      if /(発着時間.+?着)/ =~ response
        result = "#{$1}\n#{result}"
      end
    else
      result = "わからない経路だよぉ(>_<)"
    end

    result
  end
end
