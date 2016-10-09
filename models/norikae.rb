# -*- coding: utf-8 -*-


class Norikae

  def initialize

  end

  def search(message)
    if /([^0-9a-zA-Z]+)→([^0-9a-zA-Z\s]+)(?:\s*)(\u59CB\u767A){0,}(\u7D42\u96FB){0,}/i =~ message.force_encoding("UTF-8")
      cway = 0
      trainType = "乗り換え"
      puts "---"
      puts message.force_encoding("UTF-8")
    end

  end

end
