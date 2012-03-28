class Post
  
  POSTS_PATH = "#{Rails.root}/app/views/blogs"
  
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods
  
  attr_reader :id, :title, :updated_at, :created_at, :meta
  
  def initialize(file)
    @file = file
    @id   = File.basename(@file).split('.').first[5..-1]
    load_post
  end
  
  def to_s
    @id
  end
  
  class << self
    
    def all
      posts = Dir[POSTS_PATH + '/post_*']
      posts.map! { |p| Post.new(p) }
      posts.sort { |a,b| b.created_at <=> a.created_at }
    end
    
    def find(id)
      posts = Dir[POSTS_PATH + '/*']
      post  = posts.select { |p| File.basename(p) =~ /^post_#{id}.+$/ }.first
      Post.new(post)
    end
    
    def paginate(page, per_page = 5)
      all[(page * per_page), per_page]
    end
    
  end
  
  protected
  
    def load_post
      blog_meta
      @title = (@meta['title'] || @id.humanize).gsub(/-/, ' ')
    end
    
    def blog_meta
      path      = POSTS_PATH + '/meta.yml'
      @meta     = File.exists?(path) ? YAML::load(ERB.new(IO.read(path)).result) : {}
      @meta     = @meta[@id]
      
      timestamp = @meta.key?('updated_at') ? Date.strptime(meta['updated_at'], '%d/%m/%Y') : File::mtime(@file)
      
      @created_at, @updated_at = timestamp
      @meta
    end
  
end
