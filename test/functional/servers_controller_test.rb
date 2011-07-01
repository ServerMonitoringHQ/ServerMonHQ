require File.dirname(__FILE__) + '/../test_helper'

class ServersControllerTest < ActionController::TestCase
  def setup
    login_as :aaron
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:servers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create server" do
    assert_difference('Server.count') do
      post :create, :server => { :name => 'foo', :url => 'http://pulse-agent.ianpurton.com' }
    end
    assert_response :redirect
    assert_redirected_to :controller => :statistics, :id => assigns(:server).id
  end

  test "should show server" do
    get :show, :id => servers(:server_one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => servers(:server_one).id
    assert_response :success
  end

  test "should update server" do
    post :create, :server => { :name => 'foo', :url => 'http://pulse-agent.ianpurton.com' }
    put :update, :id => assigns(:server).id, :server => { :name => 'foo2' }
    assert_response :redirect
    assert_redirected_to :controller => :statistics, :id => assigns(:server).id
  end

  test "should destroy server" do
    assert_difference('Server.count', -1) do
      delete :destroy, :id => servers(:server_one).id
    end

    assert_redirected_to servers_path
  end

  test 'should redirect expired account holder to account page' do
    login_as :old_password_holder
    get :index
    assert_response :redirect
    assert_redirected_to account_url
  end
end
