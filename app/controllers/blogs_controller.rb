class BlogsController < ApplicationController
  
  caches_page :show
  
  PAGE_SIZE       = 5
  FRONT_PAGE_SIZE = 20

  layout 'marketing'

  def index
    params[:page] ||= 0
    
    @front_posts = Post.paginate(params[:page], FRONT_PAGE_SIZE)
    @posts       = Post.paginate(params[:page], PAGE_SIZE)

    respond_to do |format|
      format.html
      format.rss do
        render :layout => false
      end
    end
  end
  
  def show
    @post  = Post.find(params[:id])
    @posts = Post.paginate(0, PAGE_SIZE)
  end
  
end
