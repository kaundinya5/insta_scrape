require "dependencies"
require 'pry'
module InstaScrape
  extend Capybara::DSL

  #get a hashtag
  def self.hashtag(hashtag, include_meta_data: false)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    @posts = []
    scrape_posts(include_meta_data: include_meta_data)
  end

  #long scrape a hashtag
  def self.long_scrape_hashtag(hashtag, scrape_length, include_meta_data: false)
    visit "https://www.instagram.com/explore/tags/#{hashtag}/"
    @posts = []
    long_scrape_posts(scrape_length, include_meta_data: include_meta_data)
  end

  #long scrape a hashtag
  def self.long_scrape_user_posts(username, scrape_length, include_meta_data: false)
    @posts = []
    long_scrape_user_posts_method(username, scrape_length, include_meta_data: include_meta_data)
  end

  #get user info and posts
  def self.long_scrape_user_info_and_posts(username, scrape_length, include_meta_data: false)
    scrape_user_info(username)
    long_scrape_user_posts_method(username, scrape_length, include_meta_data: include_meta_data)
    @user = InstaScrape::InstagramUserWithPosts.new(username, @image, @post_count, @follower_count, @following_count, @description, @posts)
  end

  #get user info
  def self.user_info(username)
    scrape_user_info(username)
    @user = InstaScrape::InstagramUser.new(username, @image, @post_count, @follower_count, @following_count, @description)
  end

  #get user info and posts
  def self.user_info_and_posts(username, include_meta_data: false)
    is_private = scrape_user_info(username)
     if !is_private
      return nil
    end
    scrape_user_posts(username, include_meta_data: include_meta_data)
    @user = InstaScrape::InstagramUserWithPosts.new(username, @image, @post_count, @follower_count, @following_count, @description, @posts,@email,@is_winkl)
  end

  #get user posts only
  def self.user_posts(username, include_meta_data: false)
    scrape_user_posts(username, include_meta_data: include_meta_data)
  end

  #get user follower count
  def self.user_follower_count(username)
    scrape_user_info(username)
    return @follower_count
  end

  #get user following count
  def self.user_following_count(username)
    scrape_user_info(username)
    return @following_count
  end

  #get user post count
  def self.user_post_count(username)
    scrape_user_info(username)
    return @post_count
  end

  #get user description
  def self.user_description(username)
    scrape_user_info(username)
    return @description
  end

  private
  #post iteration method

  def self.iterate_through_posts(include_meta_data:)
    all_posts = all("article div div div a").collect do |post|
      { link: post["href"],
        image: post.find("img")["src"],
        text: post.find("img")["alt"]}
    end
    posts = all_posts.take(20)
    posts.each do |post|
      if include_meta_data
        visit(post[:link])
        date = page.find('time')["datetime"]
        username = page.first("article header div div div a")["title"]
        hi_res_image = page.all("img").last["src"]
        likes = page.find_all("div section span span")[3]["innerHTML"]
        comments = page.find_all('div div ul li').count - 1
        info = InstaScrape::InstagramPost.new(post[:link], post[:image], {
          date: date,
          text: post[:text],
          username: username,
          hi_res_image: hi_res_image,
          likes: likes,
          comments: comments,
          hashtags: text.scan(/(?:\s|^)(?:#(?!\d+(?:\s|$)))(\w+)(?=\s|$)/i).flatten
        })
      else
        info = InstaScrape::InstagramPost.new(post[:link], post[:image], { text: text })
      end
      @posts << info
    end

    #log
    # puts "POST COUNT: #{@posts.length}"
    # self.log_posts
    #return result
    return @posts
  end

  #user info scraper method
  def self.scrape_user_info(username)
    visit "https://www.instagram.com/#{username}/"
    if page.has_text?("Sorry, this page isn't available.")
      return false
    elsif  page.has_text?("This Account is Private")
      return false
    end
    @image = page.find('main header div img')["src"]
    within("header") do
      if page.first('span', :text => "posts", exact: true) == nil
        post_count_html = page.find('span', :text => "post", exact: true)['innerHTML']
      else
        post_count_html = page.find('span', :text => "posts", exact: true)['innerHTML']
      end
      @post_count = get_span_value(post_count_html)
      follower_count_html = page.find('a', :text => "followers", exact: true)['innerHTML']
      @follower_count = get_span_value(follower_count_html)
      following_count_html = page.find('a', :text => "following", exact: true)['innerHTML']
      @following_count = get_span_value(following_count_html)
      description = page.find(:xpath, '//header/section/div[2]')['innerHTML']
      @description = Nokogiri::HTML(description).text
      @description.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| @email = x }
      @is_winkl = @description.include? "winkl"
    end
  end

  #scrape posts
  def self.scrape_posts(include_meta_data:)
    begin
      # page.find('a', :text => "Load more", exact: true).click
      max_iteration = 2
      iteration = 0
      while iteration < max_iteration do
        iteration += 1
        page.execute_script "window.scrollTo(0,document.body.scrollHeight);"
        sleep 1 
        # page.execute_script "window.scrollTo(0,(document.body.scrollHeight - 5000));"
        # sleep 0.1
      end
      iterate_through_posts(include_meta_data: include_meta_data)
    rescue Capybara::ElementNotFound => e
      begin
        iterate_through_posts(include_meta_data: include_meta_data)
      end
    end
  end

  def self.long_scrape_posts(scrape_length_in_seconds, include_meta_data:)
    begin
      page.find('a', :text => "Load more", exact: true).click
      max_iteration = (scrape_length_in_seconds / 0.3)
      iteration = 0
      @loader = "."
      while iteration < max_iteration do
        puts "InstaScrape is working. Please wait.#{@loader}"
        iteration += 1
        sleep 0.1
        page.execute_script "window.scrollTo(0,document.body.scrollHeight);"
        sleep 0.1
        page.execute_script "window.scrollTo(0,(document.body.scrollHeight - 5000));"
        sleep 0.1
        @loader << "."
        system "clear"
      end
      iterate_through_posts(include_meta_data: include_meta_data)
    rescue Capybara::ElementNotFound => e
      begin
        iterate_through_posts(include_meta_data: include_meta_data)
      end
    end
  end

  def self.long_scrape_user_posts_method(username, scrape_length_in_seconds, include_meta_data:)
    @posts = []
    visit "https://www.instagram.com/#{username}/"
    long_scrape_posts(scrape_length_in_seconds, include_meta_data: include_meta_data)
  end

  def self.scrape_user_posts(username, include_meta_data:)
    @posts = []
    visit "https://www.instagram.com/#{username}/"
    scrape_posts(include_meta_data: include_meta_data)
  end

  #post logger
  def self.log_posts
    post = @posts.sample
    puts "* Printing Sample Post *"
    puts "\n"
    puts "Image: #{post.image}\n"
    puts "Link: #{post.link}\n"
    puts "Text: #{post.text}\n"
    if post.date
      puts "Date: #{post.date}\n"
      puts "Username: #{post.username}\n"
      puts "Hi Res Image: #{post.hi_res_image}\n"
      puts "Likes: #{post.likes}\n"
    end
    puts "\n"
  end

  #split away span tags from user info numbers
  def self.get_span_value(element)
    begin_split = "\">"
    end_split = "</span>"
    return element[/#{begin_split}(.*?)#{end_split}/m, 1]
  end

end
