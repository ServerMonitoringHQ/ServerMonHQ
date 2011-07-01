require File.dirname(__FILE__) + '/../test_helper'

class StatisticsControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def setup
    login_as :aaron
  end

  def test_should_get_index
    get :index, :id => servers(:server_one).id
    assert_response :success
    assert_not_nil assigns(:server)
  end

  test 'should redirect expired account holder to account page' do
    login_as :old_password_holder
    get :index, :id => servers(:server_four).id
    assert_response :redirect
    assert_redirected_to account_url
  end
end
