class InstaScrape::InstagramUserWithPosts
  attr_accessor :username, :image, :post_count, :follower_count, :following_count, :description, :posts, :posts, :email, :is_winkl
  def initialize(username, image, post_count, follower_count, following_count, description, posts,email,is_winkl)
    @username = username
    @image = image
    @post_count = post_count
    @follower_count = follower_count
    @following_count = following_count
    @description = description
    @posts = posts
    @email = email
    @is_winkl = is_winkl
  end
end
