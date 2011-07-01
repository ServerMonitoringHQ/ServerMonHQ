require File.dirname(__FILE__) + '/../test_helper'

class AccountsControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def setup
    login_as :aaron
  end

  test 'should get accounts screen' do
    get :show
    assert_response :success
    assert_not_nil assigns(:account)
  end

  test 'should not show account details' do
    login_as :regular
    get :show
    assert_response :redirect
  end
end
