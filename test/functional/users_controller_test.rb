require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(:login => '')
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'User.count' do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  def test_should_show_forgot_form
    get :forgot
    assert_response :success
  end

  test 'should show user details' do
    login_as :aaron
    get :show, :id => users(:aaron).to_param
    assert_response :success
  end

  test 'should get edit form' do
    login_as :aaron
    get :edit, :id => users(:aaron).to_param
    assert_response :success
  end

  test 'should redirect expired account holder to account page' do
    login_as :old_password_holder
    get :index
    assert_response :redirect
    assert_redirected_to account_url
  end

  protected
    def create_user(options = {})
      post :create, :user => { :login => 'quire', :email => 'quire@example.com',
        :first_name => 'Ian', :last_name => 'Purton',
        :password => 'quire69', :password_confirmation => 'quire69' }.merge(options),
        :account => { :plan_id => 1 }
    end
end
