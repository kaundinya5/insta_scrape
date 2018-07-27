class InstaScrape::InstagramPost
  attr_accessor :link, :image, :date, :text, :username, :hi_res_image, :likes, :hashtags, :comments
  def initialize(link, image, options = {})
    @image = image
    @link = link
    @date = options[:date]
    @text = options[:text]
    @username = options[:username]
    @hi_res_image = options[:hi_res_image]
    @likes = options[:likes]
    @comments = options[:comments]
    @hashtags = options[:hashtags]
  end
end
