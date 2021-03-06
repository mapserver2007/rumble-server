require 'weighted_randomizer'

class Tumblr
  HOST = 'api.mlab.com'
  PATH = '/api/1/databases/%s/collections/%s'
  HEADER = {'Content-Type' => "application/json"}

  def initialize
    @database  = Config["MLAB_DATABASE"]
    @apikey    = Config["MLAB_APIKEY"]
  end

  def get_image(keyword, count)
    contents = []
    name_master = get({:name => keyword}, Config["MLAB_NAME_COLLECTION"])

    unless name_master.empty?
      hash = nil
      name_master.each do |master|
        hash = master['hash'] if keyword == master['name']
      end
      unless hash.nil?
        image_master = get({:id => hash}, Config["MLAB_IMAGE_COLLECTION"])
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
    end

    if contents.empty?
      {state: 404, text: "…画像がみつからないよぉ"}
    else
      {state: 200, contents: contents}
    end
  end

  def get_image_info(keyword)
    image_num = 0
    image_priority_map = {}
    name_master = get({:name => keyword}, Config["MLAB_NAME_COLLECTION"])
    unless name_master.empty?
      image_master = get({:id => name_master[0]['hash']}, Config["MLAB_IMAGE_COLLECTION"])
      unless image_master.empty?
        image_num = image_master[0]['images'].size
        image_master[0]['images'].each do |image|
          if image_priority_map[image['priority']].nil?
            image_priority_map[image['priority']] = 1
          else
            image_priority_map[image['priority']] += 1
          end
        end
      end
    end

    {num: image_num, info: image_priority_map}
  end

  def update_priority(id, url, value, overwrite = false)
    result = {status: 500, value: nil}
    data = get({:id => id}, Config["MLAB_IMAGE_COLLECTION"])
    unless data.empty?
      updated_priority = 0
      urls = url.is_a?(Array) ? url : [url]
      data[0]['images'].each do |image|
        if urls.include? image['url']
          if overwrite
            image['priority'] = value
          else
            image['priority'] += value
          end

          updated_priority = image['priority']
          break
        end
      end

      if put(data, {:_id => data[0]['_id']}, Config["MLAB_IMAGE_COLLECTION"])
        result = {status: 200, value: updated_priority}
      end
    end

    result
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
      https.put(PATH % [@database, collection] + "?apiKey=#{@apikey}&q=" + cond.to_json, data.to_json, HEADER).code == "200"
    end
  end
end
