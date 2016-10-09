# -*- coding: utf-8 -*-


class Norikae

  def initialize

  end

  def search(message)

    if /([^0-9a-zA-Z]+)→([^0-9a-zA-Z\s]+)(?:\s*)(\u59CB\u767A){0,}(\u7D42\u96FB){0,}/i =~ message
      cway = 0
      trainType = "乗り換え"
      p $3
    end

  end

end
