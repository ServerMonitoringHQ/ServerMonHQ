require File.dirname(__FILE__) + '/../test_helper'

class PortsControllerTest < ActionController::TestCase

  assert_all_valid_markup

  def setup
    login_as :aaron
  end

  test "should get index" do
    get :index, :server_id => servers(:server_one).id
    assert_response :success
    assert_not_nil assigns(:ports)
  end

  test "should get new" do
    get :new, :server_id => servers(:server_one).id
    assert_response :success
  end

  test "should create port" do
    assert_difference('Port.count') do
      post :create, :port => { :address => '3306', :name => 'MySQL' }, :server_id => servers(:server_one).id
    end
    assert_redirected_to server_ports_url(servers(:server_one))
  end

  test "should show port" do
    get :show, :id => ports(:one).id, :server_id => servers(:server_one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => ports(:one).id, :server_id => servers(:server_one).id
    assert_response :success
  end

  test "should update port" do
    put :update, :id => ports(:one).id, :port => { }, :server_id => servers(:server_one).id
    assert_redirected_to server_ports_url(servers(:server_one))
  end

  test "should destroy port" do
    assert_difference('Port.count', -1) do
      delete :destroy, :id => ports(:one).id, :server_id => servers(:server_one).id
    end
    assert_redirected_to server_ports_url(servers(:server_one))
  end

  test 'should redirect expired account holder to account page' do
    login_as :old_password_holder
    get :index, :server_id => servers(:server_four).id
    assert_response :redirect
    assert_redirected_to account_url
  end
end
