class Tumblr
  HOST = 'api.mlab.com'
  PATH = '/api/1/databases/%s/collections/%s'

  def initialize
    database   = Config["MLAB_DATABASE"]
    collection = Config["MLAB_COLLECTION"]
    @apikey    = Config["MLAB_APIKEY"]
    @path      = PATH % [database, collection]
  end

  def get_image(keyword, count)
    list = get({:keyword => keyword})

    if list.any? && list[0]['contents'].any?
      contents = list[0]['contents']

      result = []
      count.times do
        index = rand(contents.size)
        result << contents[index]
        contents.delete_at(index)
      end

      return {
        :state => 200,
        :contents => result
      }
    else
      return {
        :state => 404,
        :text => "…画像がみつからないよぉ( ꒪⌓꒪)"
      }
    end
  end

  def https_start
    Net::HTTP.version_1_2
    https = Net::HTTP.new(HOST, 443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    https.start { yield https }
  end

  def get(cond)
    https_start do |https|
      JSON.parse(https.get(@path + "?apiKey=#{@apikey}&q=" + cond.to_json).body)
    end
  end
end
