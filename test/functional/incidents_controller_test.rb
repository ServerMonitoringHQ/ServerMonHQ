require File.dirname(__FILE__) + '/../test_helper'

class IncidentsControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def setup
    login_as :aaron
  end

  def test_should_show_incidents_index
    get :index
    assert_response :success
    assert_not_nil assigns(:incidents)
  end

  test 'should redirect expired account holder to account page' do
    login_as :old_password_holder
    get :index
    assert_response :redirect
    assert_redirected_to account_url
  end
end
