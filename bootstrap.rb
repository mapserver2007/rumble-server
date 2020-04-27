require 'yaml'
require 'log4r'

class Bootstrap
  def self.default
    []
  end

  def self.init(*inits)
    [default, inits].flatten.uniq.each do |cat|
      Dir.glob("#{File.dirname(__FILE__)}/#{cat}/*.rb").each do |rb|
        puts "load #{rb}"
        require rb
      end
    end
    Config.init(File.dirname(__FILE__) + '/config/config.yml')
    Logger.init
  end
end

class Logger
  def self.init
    @@logger = Log4r::Logger.new("rumble-server")
    @@logger.level = 2 # INFO
    @@logger.outputters = []
    @@logger.outputters << Log4r::StdoutOutputter.new('console', {
      :formatter => Log4r::PatternFormatter.new(
        :pattern => "[%l] %d: %M",
        :date_format => "%Y/%m/%d %H:%M:%Sm"
      )
    })
  end

  def self.method_missing(name, args)
    @@logger.send(name, args)
  end
end

class Config
  def self.init(filepath)
    self.file = filepath
  end

  def self.[](key)
    p key
    p conf
    conf[key]
  end

  def self.[]=(key,value)
    conf[key] = value
  end

  def self.file=(name)
    @@file = name
  end

  def self.conf
    begin
      if File.exists? @@file
        @@conf ||= YAML::load self.open.read
      else
        @@conf = ENV
      end
    rescue => e
      STDERR.puts e
      STDERR.puts "config.yml load error!!"
      exit 1
    end
  end

  def self.open(opt=nil, &block)
    if block_given?
      yield File.open(@@file, opt)
    else
      return File.open(@@file, opt)
    end
  end

  def self.save
    self.open 'w+' do |f|
      f.write self.to_yaml
    end
  end

  def self.to_yaml
    self.conf.to_yaml
  end

  def self.to_json
    self.conf.to_json
  end
end
