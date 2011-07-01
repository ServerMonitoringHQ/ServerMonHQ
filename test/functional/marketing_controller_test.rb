require File.dirname(__FILE__) + '/../test_helper'
class MarketingControllerTest < ActionController::TestCase
  assert_all_valid_markup

  test 'should get index page' do
    get :index
    assert_response :success
  end

  test 'should get tour page' do
    get :tour
    assert_response :success
  end

  test 'should get buy page' do
    get :buy
    assert_response :success
  end
end
