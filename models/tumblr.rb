require 'weighted_randomizer'

class Tumblr
  HOST = 'api.mlab.com'
  PATH = '/api/1/databases/%s/collections/%s'

  def initialize
    @database  = Config["MLAB_DATABASE"]
    @apikey    = Config["MLAB_APIKEY"]
  end

  def get_image(keyword, count)
    contents = []
    name_master = get({:name => keyword}, Config["MLAB_NAME_COLLECTION"])

    unless name_master.empty?
      image_master = get({:id => name_master[0]['hash']}, Config["MLAB_IMAGE_COLLECTION"])
      unless image_master.empty?
        images = image_master[0]['images']
        search_map = {}
        image_map = {}
        images.each do |image|
          search_map[image['url']] = image['priority']
          image_map[image['url']] = image
        end

        count.times do
          randomizer = WeightedRandomizer.new(search_map)
          key = randomizer.sample
          break if key.nil?

          contents << {
            id: image_master[0]['id'],
            img: image_map[key]['url'],
            text: image_map[key]['text'].empty? ? "(no title)" : image_map[key]['text']
          }
          search_map.delete(key)
        end
      end
    end

    if contents.empty?
      {state: 404, text: "…画像がみつからないよぉ( \uA4AA\u2313\uA4AA)"}
    else
      {state: 200, contents: contents}
    end
  end

  def update_priority(id, image, value)
    data = get({:id => id}, Config["MLAB_IMAGE_COLLECTION"])
    unless data.empty?
      p data
    end
  end

  def https_start
    Net::HTTP.version_1_2
    https = Net::HTTP.new(HOST, 443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    https.start { yield https }
  end

  def get(cond, collection)
    https_start do |https|
      JSON.parse(https.get(PATH % [@database, collection] + "?apiKey=#{@apikey}&q=" + cond.to_json).body)
    end
  end

  def put(data, cond, collection)
    https_start do |https|
      https.put(@path + "?apiKey=#{@apikey}&q=" + cond.to_json, data.to_json, @header).code == "200"
    end
  end
end
