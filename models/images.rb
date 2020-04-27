require 'mongo'

class Images
  def initialize
    p "mongodb://#{Config["MLAB_USER"]}:#{Config["MLAB_PASSWORD"]}@#{Config["MLAB_HOST"]}:#{Config["MLAB_PORT"]}/#{Config["MLAB_DATABASE"]}"
    client = Mongo::Client.new("mongodb://#{Config["MLAB_USER"]}:#{Config["MLAB_PASSWORD"]}@#{Config["MLAB_HOST"]}:#{Config["MLAB_PORT"]}/#{Config["MLAB_DATABASE"]}")
    @collection_names = client[:rumble_name_master]
    @collection_images = client[:rumble_image_master]
  end

  def get_images(name)
    query = []
    images = []
    @collection_names.find(origin_name: name).each do |data|
      query << {id: data['hash']}
    end

    @collection_images.find(:$or => query).each do |data|
      data['images'].each do |image|
        images << {url: image['url'], text: image['text'] }
      end
    end

    images
  end
end