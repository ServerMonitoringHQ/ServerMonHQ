require File.dirname(__FILE__) + '/../test_helper'

class PagesControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def setup
    login_as :aaron
  end

  def test_should_show_list_of_pages
    get :index, :server_id => servers(:server_one).id
    assert_response :success
    assert_not_nil assigns(:pages)
    assert_not_nil assigns(:server)
  end

  def test_should_show_page
    get :show, :id => pages(:one).id, :server_id => servers(:server_one).id
    assert_response :success
    assert_not_nil assigns(:page)
    assert_not_nil assigns(:server)
  end

  def test_should_get_page_creation_form
    get :new, :server_id => servers(:server_one).id
    assert_response :success
    assert_not_nil assigns(:page)
    assert_not_nil assigns(:server)
  end

  def test_should_get_page_edition_form
    get :edit, :id => pages(:one).id, :server_id => servers(:server_one).id
    assert_response :success
    assert_not_nil assigns(:page)
    assert_not_nil assigns(:server)
  end

  def test_should_remove_page
    assert_difference('Page.count', -1) do
      delete :destroy, :id => pages(:one).id, :server_id => servers(:server_one).id
      assert_response :redirect
      assert_redirected_to server_pages_url(servers(:server_one).id)
    end
  end

  def test_should_create_new_page
    assert_difference('Page.count') do
      post :create, :server_id => servers(:server_one).id,
           :page => { :url => 'http://foo.bar', :title => 'foo', :search_text => 'bar' }
      assert_response :redirect
      assert_redirected_to server_pages_url(servers(:server_one).id)
    end
  end

  def test_update_page_properties
    put :update, :server_id => servers(:server_one).id,
        :id => pages(:one).id, :page => { :title => 'baz' }
    assert_response :redirect
    assert_redirected_to server_pages_url(servers(:server_one).id)
  end

  test 'should redirect expired account holder to account page' do
    login_as :old_password_holder
    get :index, :server_id => servers(:server_four).id
    assert_response :redirect
    assert_redirected_to account_url
  end
end
