# -*- coding: utf-8 -*-
require 'httpclient'
require 'uri'

class Norikae
  def initialize(from, to, shihatu, shuden)
    @from, @to, @shihatu, @shuden = from, to, shihatu, shuden
    @type = {
      :cway => 0, :trainType => "乗り換え"
    }

    if !shihatu.nil?
      @type[:cway] = 2 # 始発
      @type[:trainType] = shihatu
    elsif !shuden.nil?
      @type[:cway] = 3 # 終電
      @type[:trainType] = shuden
    end
  end

  def search
    url = "http://www.jorudan.co.jp/norikae/cgi/nori.cgi?Sok=1&eki1=#{URI.escape(@from)}&eki2=#{URI.escape(@to)}&type=t&Cway=#{@type[:cway]}"
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
